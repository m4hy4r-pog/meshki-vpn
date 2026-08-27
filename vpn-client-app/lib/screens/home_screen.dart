// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import '../models/server.dart';

class HomeScreen extends StatelessWidget {
  final List<ServerConfig> servers = [
    ServerConfig(
      id: '1',
      name: 'Iran → Turkey',
      host: 'YOUR_TURKEY_VPS_IP',
      port: 1194,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final vpn = Provider.of<VpnProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('VPN Client', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.username ?? 'User'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _statRow('Status', user?.status ?? 'Unknown'),
                  _statRow('Expiry', user?.expiryText ?? 'N/A'),
                  _statRow('Usage', user?.totalUsed ?? '0 B'),
                  _statRow('Quota', user?.totalQuota ?? 'Unlimited'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Connection Status
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(vpn.status.state).withOpacity(0.1),
                border: Border.all(
                  color: _getStatusColor(vpn.status.state),
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    vpn.isConnected ? Icons.lock_open : Icons.lock,
                    size: 48,
                    color: _getStatusColor(vpn.status.state),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(vpn.status.state),
                    style: TextStyle(
                      color: _getStatusColor(vpn.status.state),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Server Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ServerConfig>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1C1C1E),
                  value: vpn.selectedServer ?? servers.first,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (s) => vpn.selectServer(s!),
                  items: servers.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Connect/Disconnect Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: vpn.isConnecting
                    ? null
                    : () => _toggleConnection(context, auth, vpn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: vpn.isConnected
                      ? Colors.redAccent
                      : const Color(0xFF00D26A),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  vpn.isConnected ? 'Disconnect' : 'Connect',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (vpn.status.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  vpn.status.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Color _getStatusColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return const Color(0xFF00D26A);
      case ConnectionState.connecting:
      case ConnectionState.disconnecting:
        return Colors.orange;
      case ConnectionState.error:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.disconnecting:
        return 'Disconnecting...';
      case ConnectionState.error:
        return 'Error';
      default:
        return 'Disconnected';
    }
  }

  Future<void> _toggleConnection(BuildContext ctx, AuthProvider auth, VpnProvider vpn) async {
    if (vpn.isConnected) {
      await vpn.disconnect();
    } else {
      final creds = await auth._authService.getCredentials(); // Fix this reference
      if (creds != null) {
        await vpn.connect(creds['username']!, creds['password']!);
      }
    }
  }
}
