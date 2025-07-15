import 'package:flutter/material.dart';
import 'dart:async';
import 'bluetooth_service.dart';

class SensorsPage extends StatefulWidget {
  @override
  _SensorsPageState createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  // Sensor data
  double currentLux = 0.0;
  int currentTVOC = 0;
  int currentECO2 = 0;
  int typingIdleSeconds = 0;

  // Stream subscriptions
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, String>>? _sensorSubscription;

  @override
  void initState() {
    super.initState();
    _listenToSensorData();
  }

  void _listenToSensorData() {
    // 监听传感器数据
    _sensorSubscription = PomodoroBluetoothService().sensorStream.listen((sensorData) {
      if (mounted) {
        setState(() {
          currentLux = double.tryParse(sensorData['LUX'] ?? '0') ?? 0.0;
          currentTVOC = int.tryParse(sensorData['TVOC'] ?? '0') ?? 0;
          currentECO2 = int.tryParse(sensorData['ECO2'] ?? '0') ?? 0;
          typingIdleSeconds = int.tryParse(sensorData['TYPING_IDLE'] ?? '0') ?? 0;
        });
      }
    });

    // 监听连接状态变化
    _connectionSubscription = PomodoroBluetoothService().connectionStream.listen((connected) {
      print("Connection status changed in SensorsPage: $connected");
      if (mounted) {
        setState(() {});
        
        if (!connected) {
          // 断开连接时重置传感器数据
          setState(() {
            currentLux = 0.0;
            currentTVOC = 0;
            currentECO2 = 0;
            typingIdleSeconds = 0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = PomodoroBluetoothService().isConnected;
    print("Building SensorsPage UI - isConnected: $isConnected");
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Environment Sensors', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: Colors.white,
            ),
            onPressed: isConnected 
                ? () => PomodoroBluetoothService().disconnect() 
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildConnectionStatus(),
            SizedBox(height: 20),
            _buildSensorCard(),
            SizedBox(height: 20),
            _buildDetailedSensorCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    bool isConnected = PomodoroBluetoothService().isConnected;
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isConnected 
                ? [Colors.green[400]!, Colors.green[600]!]
                : [Colors.grey[400]!, Colors.grey[600]!],
          ),
        ),
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.sensors : Icons.sensors_off,
              size: 40,
              color: Colors.white,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Sensors Active' : 'Sensors Offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isConnected 
                        ? 'Real-time data available' 
                        : 'Connect to robot first',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (isConnected)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard() {
    bool isConnected = PomodoroBluetoothService().isConnected;
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.blue[600], size: 28),
                SizedBox(width: 12),
                Text(
                  "Sensor Overview",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSensorItem("Light", "${currentLux.toStringAsFixed(1)} lux", 
                    Icons.wb_sunny, _getLightColor(currentLux, isConnected)),
                _buildSensorItem("Air Quality", "$currentTVOC ppb", 
                    Icons.air, _getAirQualityColor(currentTVOC, isConnected)),
                _buildSensorItem("CO2", "$currentECO2 ppm", 
                    Icons.cloud, _getCO2Color(currentECO2, isConnected)),
                _buildSensorItem("Typing", "${typingIdleSeconds}s idle", 
                    Icons.keyboard, _getTypingColor(typingIdleSeconds, isConnected)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedSensorCards() {
    return Column(
      children: [
        _buildDetailedSensorCard(
          "Light Sensor",
          Icons.wb_sunny,
          currentLux,
          "lux",
          _getLightColor(currentLux, PomodoroBluetoothService().isConnected),
          _getLightDescription(currentLux),
          Colors.amber,
        ),
        SizedBox(height: 16),
        _buildDetailedSensorCard(
          "Air Quality (TVOC)",
          Icons.air,
          currentTVOC.toDouble(),
          "ppb",
          _getAirQualityColor(currentTVOC, PomodoroBluetoothService().isConnected),
          _getAirQualityDescription(currentTVOC),
          Colors.green,
        ),
        SizedBox(height: 16),
        _buildDetailedSensorCard(
          "CO2 Level",
          Icons.cloud,
          currentECO2.toDouble(),
          "ppm",
          _getCO2Color(currentECO2, PomodoroBluetoothService().isConnected),
          _getCO2Description(currentECO2),
          Colors.blue,
        ),
        SizedBox(height: 16),
        _buildTypingCard(),
      ],
    );
  }

  Widget _buildDetailedSensorCard(
    String title,
    IconData icon,
    double value,
    String unit,
    Color statusColor,
    String description,
    Color cardColor,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cardColor.withOpacity(0.1), cardColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: cardColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            PomodoroBluetoothService().isConnected 
                                ? "${value.toStringAsFixed(1)} $unit"
                                : "N/A",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: statusColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingCard() {
    bool isConnected = PomodoroBluetoothService().isConnected;
    Color typingColor = _getTypingColor(typingIdleSeconds, isConnected);
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.purple.withOpacity(0.1), Colors.purple.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.keyboard, color: Colors.purple, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Typing Activity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isConnected ? "${typingIdleSeconds}s" : "N/A",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: typingColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "idle",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: typingColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: isConnected ? (typingIdleSeconds / 60).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(typingColor),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typingColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typingColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: typingColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTypingDescription(typingIdleSeconds),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorItem(String label, String value, IconData icon, Color color) {
    bool isConnected = PomodoroBluetoothService().isConnected;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(
            isConnected ? value : "N/A", 
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  // Color and description helper methods
  Color _getLightColor(double lux, bool isConnected) {
    if (!isConnected) return Colors.grey[400]!;
    if (lux < 100) return Colors.orange;
    if (lux < 500) return Colors.yellow[700]!;
    return Colors.green;
  }

  Color _getAirQualityColor(int tvoc, bool isConnected) {
    if (!isConnected) return Colors.grey[400]!;
    if (tvoc > 800) return Colors.red;
    if (tvoc > 400) return Colors.orange;
    return Colors.green;
  }

  Color _getCO2Color(int eco2, bool isConnected) {
    if (!isConnected) return Colors.grey[400]!;
    if (eco2 > 1000) return Colors.red;
    if (eco2 > 600) return Colors.orange;
    return Colors.green;
  }

  Color _getTypingColor(int idleSeconds, bool isConnected) {
    if (!isConnected) return Colors.grey[400]!;
    if (idleSeconds > 20) return Colors.orange;
    if (idleSeconds > 10) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getLightDescription(double lux) {
    if (!PomodoroBluetoothService().isConnected) return "Connect to robot to get light data";
    if (lux < 100) return "Too dark - consider turning on lights";
    if (lux < 500) return "Adequate lighting for work";
    return "Excellent lighting conditions";
  }

  String _getAirQualityDescription(int tvoc) {
    if (!PomodoroBluetoothService().isConnected) return "Connect to robot to get air quality data";
    if (tvoc > 800) return "Poor air quality - ventilate the room";
    if (tvoc > 400) return "Moderate air quality";
    return "Good air quality";
  }

  String _getCO2Description(int eco2) {
    if (!PomodoroBluetoothService().isConnected) return "Connect to robot to get CO2 data";
    if (eco2 > 1000) return "High CO2 - open windows for fresh air";
    if (eco2 > 600) return "Moderate CO2 levels";
    return "Low CO2 - good ventilation";
  }

  String _getTypingDescription(int idleSeconds) {
    if (!PomodoroBluetoothService().isConnected) return "Connect to robot to get typing data";
    if (idleSeconds > 20) return "Long idle time - take a break or stretch";
    if (idleSeconds > 10) return "Moderate activity";
    return "Active typing detected";
  }
}