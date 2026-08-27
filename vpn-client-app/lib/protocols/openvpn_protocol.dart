// lib/protocols/openvpn_protocol.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'vpn_protocol.dart';
import '../models/server.dart';

class OpenVpnProtocol implements VpnProtocol {
  Process? _process;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _currentStatus = ConnectionStatus(state: ConnectionState.disconnected);

  @override
  String get protocolName => 'OpenVPN';

  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> isAvailable() async {
    // Check if openvpn.exe exists in bundled location
    final exePath = await _getOpenVpnPath();
    return File(exePath).exists();
  }

  @override
  Future<void> connect(ServerConfig config, String username, String password) async {
    try {
      _updateState(ConnectionState.connecting);

      // 1. Get app directory for temp files
      final appDir = await getApplicationSupportDirectory();
      final tempDir = Directory(path.join(appDir.path, 'temp'));
      if (!tempDir.existsSync()) tempDir.createSync(recursive: true);

      // 2. Write credentials file
      final authFile = File(path.join(tempDir.path, 'auth.txt'));
      await authFile.writeAsString('$username\n$password');

      // 3. Write config file (embedded asset copied to temp)
      final configFile = File(path.join(tempDir.path, 'config.ovpn'));
      final embeddedConfig = await _loadEmbeddedConfig();
      
      // Inject auth-user-pass and remote server
      final modifiedConfig = _modifyConfig(
        embeddedConfig,
        remote: config.host,
        port: config.port,
        authFile: authFile.path,
      );
      await configFile.writeAsString(modifiedConfig);

      // 4. Launch openvpn.exe
      final exePath = await _getOpenVpnPath();
      _process = await Process.start(
        exePath,
        [
          '--config', configFile.path,
          '--auth-user-pass', authFile.path,
          '--verb', '3',
        ],
        runInShell: false,
      );

      // 5. Parse output
      _process!.stdout.transform(utf8.decoder).listen(_parseOutput);
      _process!.stderr.transform(utf8.decoder).listen(_parseOutput);

      _process!.exitCode.then((code) {
        if (code != 0 && _currentStatus.state == ConnectionState.connecting) {
          _updateState(ConnectionState.error, error: 'Connection failed (exit code: $code)');
        } else if (_currentStatus.state == ConnectionState.connected) {
          _updateState(ConnectionState.disconnected);
        }
      });

    } catch (e) {
      _updateState(ConnectionState.error, error: e.toString());
    }
  }

  @override
  Future<void> disconnect() async {
    _updateState(ConnectionState.disconnecting);
    _process?.kill();
    _process = null;
    _updateState(ConnectionState.disconnected);
  }

  Future<String> _getOpenVpnPath() async {
    // In production, bundle openvpn.exe in your app package
    // For dev, point to installed location
    final appDir = await getApplicationSupportDirectory();
    return path.join(appDir.path, 'bin', 'openvpn.exe');
  }

  Future<String> _loadEmbeddedConfig() async {
    // Load from assets
    // You'll need to add rootBundle import
    return ''; // Load from assets/configs/default.ovpn
  }

  String _modifyConfig(String config, {
    required String remote,
    required int port,
    required String authFile,
  }) {
    var lines = config.split('\n');
    
    // Remove existing remote lines
    lines.removeWhere((l) => l.trim().startsWith('remote '));
    
    // Add our remote and auth
    lines.insert(0, 'remote $remote $port');
    lines.insert(1, 'auth-user-pass $authFile');
    
    return lines.join('\n');
  }

  void _parseOutput(String line) {
    print('[OpenVPN] $line');
    
    if (line.contains('Initialization Sequence Completed')) {
      _updateState(ConnectionState.connected);
    } else if (line.contains('AUTH_FAILED')) {
      _updateState(ConnectionState.error, error: 'Authentication failed. Check username/password.');
      disconnect();
    } else if (line.contains('Connection refused') || line.contains('No route to host')) {
      _updateState(ConnectionState.error, error: 'Server unreachable.');
    }
  }

  void _updateState(ConnectionState state, {String? error}) {
    _currentStatus = ConnectionStatus(
      state: state,
      errorMessage: error,
      connectedSince: state == ConnectionState.connected ? DateTime.now() : _currentStatus.connectedSince,
    );
    _statusController.add(_currentStatus);
  }
}
