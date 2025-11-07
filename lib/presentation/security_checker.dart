import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_protector/flutter_protector.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

class SecurityCheckerScreen extends StatefulWidget {
  @override
  _SecurityCheckerScreenState createState() => _SecurityCheckerScreenState();
}

class _SecurityCheckerScreenState extends State<SecurityCheckerScreen>
    with SingleTickerProviderStateMixin {
  bool loading = false;
  String _deviceStatus = "Checking...";
  String _jailbreakStatus = "Checking...";
  String _wifiSecurity = "Checking...";
  String _vpnStatus = "Checking...";
  String _deviceInfo = "Fetching...";
  String _issueStatus = "Checking...";
  List<JailbreakIssue> _issues = [];
  List<AppInfo> _installedApps = [];
  List<AppInfo> _harmfulApps = [];
  List<AppInfo> _highRiskApps = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  // final List<String> _blacklistedApps = [
  //   "Lucky Patcher",
  //   "Game Guardian",
  //   "CreeHack",
  //   "Freedom",
  //   "Root Checker",
  //   "Cheat Engine"
  // ];
final List<String> _blacklistedApps = [
  "Lucky Patcher", "Game Guardian", "CreeHack", "Freedom", "Root Checker",
  "Cheat Engine", "zANTI", "AndroRAT", "DroidSheep", "KingRoot", "Magisk",
  "SuperSU", "Parallel Space", "App Cloner", "Dual Space"
];

  final List<String> highRiskPermissions = [
  "android.permission.SYSTEM_ALERT_WINDOW", "android.permission.READ_SMS",
  "android.permission.SEND_SMS", "android.permission.RECEIVE_SMS",
  "android.permission.WRITE_SETTINGS", "android.permission.ACCESS_FINE_LOCATION",
  "android.permission.RECORD_AUDIO", "android.permission.CAMERA",
  "android.permission.READ_CALL_LOG", "android.permission.REQUEST_INSTALL_PACKAGES"
];


  @override
  void initState() {
    super.initState();
    loading = true;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);

    // Delay for 2 seconds before checking device security
    Future.delayed(const Duration(seconds: 2), () {
      checkDeviceSecurity();
      setState(() {
        loading = false; // Stop loading after 2s
      });
    });
  }

  Future<void> checkDeviceSecurity() async {
    await Future.wait([
      checkRootStatus(),
      checkJailbreakStatus(),
      checkWiFiSecurity(),
      checkVPNProxyStatus(),
      getDeviceInfo(),
      checkIssues(),
      getInstalledApps(),
    ]);
  }

  Future<void> checkRootStatus() async {
    bool isRooted = await FlutterProtector().isDeviceRooted() ?? false;
    setState(() => _deviceStatus = isRooted ? "Rooted ❌" : "Not Rooted ✅");
  }

  Future<void> checkJailbreakStatus() async {
    bool isJailBroken = await JailbreakRootDetection.instance.isJailBroken;
    setState(() => _jailbreakStatus = isJailBroken ? "Jailbroken ❌" : "Secure ✅");
  }

  Future<void> checkWiFiSecurity() async {
    final info = NetworkInfo();
    String? wifiBSSID = await info.getWifiBSSID();
    setState(() => _wifiSecurity = wifiBSSID == null ? "⚠️ Open Wi-Fi" : "✅ Secured Wi-Fi");
  }

  Future<void> checkVPNProxyStatus() async {
    bool isUsingVPN = await FlutterProtector().isVpnConnected() ?? false;
    bool isUsingProxy = await FlutterProtector().isProxySet() ?? false;
    setState(() => _vpnStatus = (isUsingVPN || isUsingProxy) ? "VPN/Proxy Detected ❌" : "No VPN/Proxy ✅");
  }

  Future<void> getDeviceInfo() async {
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    setState(() {
      _deviceInfo = "Device: ${androidInfo.model}\nAndroid: ${androidInfo.version.release}\nSecurity Patch: ${androidInfo.version.securityPatch}";
    });
  }

  Future<void> checkIssues() async {
    final checkForIssues = await JailbreakRootDetection.instance.checkForIssues;
    setState(() {
      _issueStatus = (checkForIssues.isNotEmpty) ? "${checkForIssues.length} issues Detected ❌" : "No Issues ✅";
      _issues = checkForIssues;
    });
  }

Future<void> getInstalledApps() async {
  List<AppInfo> apps = await InstalledApps.getInstalledApps();
  List<AppInfo> harmful = apps.where((app) => _blacklistedApps.contains(app.name)).toList();
  List<AppInfo> highRisk = [];

  // Check if the app has high-risk permissions (limited due to Android restrictions)
  for (AppInfo app in apps) {
    bool hasHighRiskPermission = await checkHighRiskPermissions();
    if (hasHighRiskPermission) {
      highRisk.add(app);
    }
  }

  setState(() {
    _installedApps = apps;
    _harmfulApps = harmful;
    _highRiskApps = highRisk;
  });
}

/// Function to check high-risk permissions for the current app
Future<bool> checkHighRiskPermissions() async {
  List<Permission> riskyPermissions = [
    Permission.systemAlertWindow,
    Permission.sms,
    Permission.phone,
    Permission.locationAlways,
    Permission.microphone,
  ];

  for (Permission perm in riskyPermissions) {
    if (await perm.status.isGranted) {
      return true; // Found at least one risky permission
    }
  }
  return false;
}


  // Future<void> getInstalledApps() async {
  //   List<AppInfo> apps = await InstalledApps.getInstalledApps();
  //   List<AppInfo> harmful = apps.where((app) => _blacklistedApps.contains(app.name)).toList();
  //   List<AppInfo> highRisk = apps.where((app) => app.permissions.any((perm) => _highRiskPermissions.contains(perm))).toList();
  //   setState(() {
  //     _installedApps = apps;
  //     _harmfulApps = harmful;
  //     _highRiskApps = highRisk;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Security Scanner", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
      ),
      body: loading
          ? Center( // Show loading animation
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.blue, Colors.blueAccent.shade700],
                        radius: 0.85,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent,
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.security, size: 100, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            SizedBox(
              height: 40,
            ),
            Text(
              "Scanning...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            )
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Security scanner logo (can remove if you want only in loading)
          Center(
            child: Icon(Icons.verified_user,
                size: 100, color: Colors.greenAccent),
          ),
          const SizedBox(height: 20),
          buildSecurityStatus("Root Status", _deviceStatus),
          buildSecurityStatus("Jailbreak Status", _jailbreakStatus),
          buildSecurityStatus("Wi-Fi Security", _wifiSecurity),
          buildSecurityStatus("VPN & Proxy", _vpnStatus),
          buildSecurityStatus("Device Info", _deviceInfo),
          buildSecurityStatus("Issues Status", _issueStatus),
          buildIssueList("Detected Issues", _issues),
          buildAppList("Harmful Apps Detected", _harmfulApps),
          buildAppList("High-Risk Apps Detected", _highRiskApps),
        ],
      ),
    );
  }


  Widget buildSecurityStatus(String title, String status) {
    return Card(
      color: Colors.grey[900],
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(status, style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget buildIssueList(String title, List<JailbreakIssue> issues) {
    return Card(
      color: Colors.orange,
      child: ExpansionTile(
        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        children: issues.isEmpty
            ? [Padding(padding: EdgeInsets.all(8.0), child: Text("No issues detected", style: TextStyle(color: Colors.white)))]
            : issues.map((issue) => ListTile(title: Text(issue.name, style: TextStyle(color: Colors.white)))).toList(),
      ),
    );
  }
    Widget buildAppList(String title, List<AppInfo> apps) {
    return Card(
      color: Colors.redAccent,
      child: ExpansionTile(
        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        children: apps.isEmpty
            ? [Padding(padding: EdgeInsets.all(8.0), child: Text("No apps detected", style: TextStyle(color: Colors.white)))]
            : apps.map((app) => ListTile(title: Text(app.name, style: TextStyle(color: Colors.white)))).toList(),
      ),
    );
  }
}