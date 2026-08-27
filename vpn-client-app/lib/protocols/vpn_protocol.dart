// lib/protocols/vpn_protocol.dart
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class ConnectionStatus {
  final ConnectionState state;
  final String? errorMessage;
  final DateTime? connectedSince;
  final String? serverIp;

  ConnectionStatus({
    required this.state,
    this.errorMessage,
    this.connectedSince,
    this.serverIp,
  });
}

abstract class VpnProtocol {
  String get protocolName;
  Stream<ConnectionStatus> get statusStream;
  Future<void> connect(ServerConfig config, String username, String password);
  Future<void> disconnect();
  Future<bool> isAvailable();
}
