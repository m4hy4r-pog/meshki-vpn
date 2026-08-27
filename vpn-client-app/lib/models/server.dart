// lib/models/server.dart
class ServerConfig {
  final String id;
  final String name;
  final String host;
  final int port;
  final String protocol; // "openvpn", "vless" (future)

  ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.protocol = 'openvpn',
  });
}
