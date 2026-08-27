// lib/providers/vpn_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../protocols/vpn_protocol.dart';
import '../protocols/openvpn_protocol.dart';
import '../models/server.dart';

class VpnProvider extends ChangeNotifier {
  VpnProtocol? _protocol;
  ConnectionStatus _status = ConnectionStatus(state: ConnectionState.disconnected);
  ServerConfig? _selectedServer;
  StreamSubscription? _statusSub;

  VpnProvider() {
    _protocol = OpenVpnProtocol();
    _statusSub = _protocol!.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });
  }

  ConnectionStatus get status => _status;
  bool get isConnected => _status.state == ConnectionState.connected;
  bool get isConnecting => _status.state == ConnectionState.connecting;
  ServerConfig? get selectedServer => _selectedServer;

  void selectServer(ServerConfig server) {
    _selectedServer = server;
    notifyListeners();
  }

  Future<void> connect(String username, String password) async {
    if (_selectedServer == null || _protocol == null) return;
    await _protocol!.connect(_selectedServer!, username, password);
  }

  Future<void> disconnect() async {
    await _protocol?.disconnect();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _protocol?.disconnect();
    super.dispose();
  }
}
