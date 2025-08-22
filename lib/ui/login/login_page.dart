// lib/ui/login/login_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart' hide Padding;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/environment.dart';
import 'package:flutter/foundation.dart';

// 定义响应数据模型
class LoginResponse {
  final UserResponse user;
  final DeviceResponse device;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  LoginResponse({
    required this.user,
    required this.device,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: UserResponse.fromJson(json['user']),
      device: DeviceResponse.fromJson(json['device']),
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresIn: json['expires_in'],
    );
  }
}

class UserResponse {
  final int id;
  final String username;
  final String email;
  final String createdAt;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      createdAt: json['created_at'],
    );
  }
}

class DeviceResponse {
  final int id;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String createdAt;
  final String lastLoginAt;

  DeviceResponse({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(
      id: json['id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      createdAt: json['created_at'],
      lastLoginAt: json['last_login_at'],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  // 设备相关信息
  late String _deviceID;
  late String _deviceName;
  late String _deviceType;
  late String _publicKey;
  late String _privateKey;

  bool _isLoading = false;
  bool _isInitializing = true; // 新增：标记是否正在初始化


  // 创建Logger实例
  static final Logger _logger = Logger('LoginPage');

  @override
  void initState() {
    super.initState();
    // 配置日志输出
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // 在调试模式下打印日志
        debugPrint('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });

    _logger.info('LoginPage 初始化');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeviceInfo();
    });
  }

    void _initializeDeviceInfo() async {
  _logger.info('开始初始化设备信息');

  try {
    // 获取或生成设备ID
    _deviceID = await _getOrCreateDeviceID();
    _logger.info('设备ID: $_deviceID');

    // 获取设备名称
    _deviceName = _getDeviceName();
    _logger.info('设备名称: $_deviceName');

    // 获取设备类型
    _deviceType = _getDeviceType();
    _logger.info('设备类型: $_deviceType');

    // 获取或生成RSA密钥对
    await _getOrCreateKeyPair();
  } catch (e, stackTrace) {
    _logger.severe('初始化设备信息失败: $e', e, stackTrace);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('初始化失败，请重新启动应用')),
      );
    }
  } finally {
    // 初始化完成后更新状态
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
    _logger.info('设备信息初始化完成');
  }
}


Future<void> _getOrCreateKeyPair() async {
  _logger.info('获取或创建RSA密钥对');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? publicKey = prefs.getString('public_key');
  String? privateKey = prefs.getString('private_key');

  if (publicKey == null ||
      publicKey.isEmpty ||
      privateKey == null ||
      privateKey.isEmpty) {
    _logger.info('未找到现有密钥对，生成新的RSA密钥对');

    try {
      // 在 isolate 中生成RSA密钥对，避免阻塞UI线程
      // 对于Web平台，使用较小的密钥长度以减少计算时间
      const keySize = kIsWeb ? 1024 : 2048;

      // 显示加载提示
      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }

      // 使用异步延迟确保UI更新
      await Future.delayed(const Duration(milliseconds: 100));

      final keyPair = await compute(_generateRSAKeyPairHelper, keySize);

      // 将公钥和私钥转换为PEM格式
      _publicKey = CryptoUtils.encodeRSAPublicKeyToPem(
          keyPair.publicKey);
      _privateKey = CryptoUtils.encodeRSAPrivateKeyToPem(
          keyPair.privateKey);

      // 保存到本地存储
      await prefs.setString('public_key', _publicKey);
      await prefs.setString('private_key', _privateKey);
      _logger.info('新密钥对已生成并保存');
    } catch (e, stackTrace) {
      _logger.severe('生成密钥对失败: $e', e, stackTrace);
      rethrow;
    }
  } else {
    // 使用已存在的密钥对
    _publicKey = publicKey;
    _privateKey = privateKey;
    _logger.info('使用现有密钥对');
  }
}



  Future<String> _getOrCreateDeviceID() async {
    _logger.info('获取或创建设备ID');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null || deviceId.isEmpty) {
      _logger.info('未找到现有设备ID，生成新的设备ID');
      // 生成新的设备ID
      deviceId = _generateDeviceID();
      // 保存到本地存储
      await prefs.setString('device_id', deviceId);
      _logger.info('新设备ID已保存: $deviceId');
    } else {
      _logger.info('使用现有设备ID: $deviceId');
    }

    return deviceId;
  }

  String _generateDeviceID() {
    _logger.info('生成设备ID');
    // 生成设备ID的算法
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    final deviceId = base64Url.encode(values);
    _logger.fine('生成的设备ID: $deviceId');
    return deviceId;
  }

  String _getDeviceName() {
    _logger.info('获取设备名称');
    // 根据平台获取设备名称
    String deviceName;

    // 在Web平台上，Platform.isX方法不可用，需要使用其他方式检测
    if (kIsWeb) {
      deviceName = 'Web Browser';
    } else if (Platform.isAndroid) {
      deviceName = 'Android Device';
    } else if (Platform.isIOS) {
      deviceName = 'iOS Device';
    } else if (Platform.isMacOS) {
      deviceName = 'macOS Device';
    } else if (Platform.isWindows) {
      deviceName = 'Windows Device';
    } else if (Platform.isLinux) {
      deviceName = 'Linux Device';
    } else {
      deviceName = 'Unknown Device';
    }

    _logger.fine('设备名称确定为: $deviceName');
    return deviceName;
  }


  String _getDeviceType() {
    _logger.info('确定设备类型');
    // 根据平台确定设备类型
    String deviceType;

    // 在Web平台上，Platform.isX方法不可用，需要使用其他方式检测
    if (kIsWeb) {
      deviceType = 'web';
    } else if (Platform.isAndroid || Platform.isIOS) {
      deviceType = 'mobile';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      deviceType = 'desktop';
    } else {
      deviceType = 'web'; // 默认为web
    }

    _logger.fine('设备类型确定为: $deviceType');
    return deviceType;
  }



  // 添加一个静态辅助方法，用于在 isolate 中执行
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeyPairHelper(int keySize) {
    // 创建随机数生成器
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // 配置RSA密钥生成参数
    final keyGenerator = RSAKeyGenerator();
    keyGenerator.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.from(65537), keySize, 64),
      secureRandom,
    ));

    // 生成密钥对
    return keyGenerator.generateKeyPair();
  }

  @override
  void dispose() {
    _logger.info('LoginPage 销毁');
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    _logger.info('开始登录流程');
    if (_formKey.currentState!.validate()) {
      _logger.info('表单验证通过，准备发送登录请求');
      setState(() {
        _isLoading = true;
      });

      try {
        final loginData = {
          'username': _identifierController.text,
          'password': _passwordController.text,
          'device_id': _deviceID,
          'device_name': _deviceName,
          'device_type': _deviceType,
          'public_key': _publicKey,
        };

        _logger.info('发送登录请求到: ${Environment.loginUrl}');
        _logger.fine('请求数据: $loginData');

        final response = await http.post(
          Uri.parse(Environment.loginUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(loginData),
        );

        _logger.info('收到响应，状态码: ${response.statusCode}');

        if (response.statusCode == 200) {
          _logger.info('登录成功');
          // 登录成功
          final responseData = jsonDecode(response.body);
          final loginResponse = LoginResponse.fromJson(responseData);
          _logger.fine('响应数据: $responseData');

          // 保存用户信息和认证令牌到SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', loginResponse.user.id);
          await prefs.setString('username', loginResponse.user.username);
          await prefs.setString('email', loginResponse.user.email);
          await prefs.setString('access_token', loginResponse.accessToken);
          await prefs.setString('refresh_token', loginResponse.refreshToken);
          await prefs.setInt('expires_in', loginResponse.expiresIn);
          await prefs.setInt('device_id_db', loginResponse.device.id);
          await prefs.setString('last_login_at', loginResponse.device.lastLoginAt);

          _logger.info('用户信息已保存到本地存储');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登录成功')),
            );

            // 登录成功后返回主页
            Navigator.pop(context);
          }
        } else {
          _logger.warning('登录失败，状态码: ${response.statusCode}');
          // 登录失败
          String errorMessage = '登录失败';
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
            _logger.fine('错误详情: $errorData');
          } catch (e) {
            _logger.warning('解析错误信息失败: $e');
            // 解析错误信息失败，使用默认错误信息
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      } catch (error, stackTrace) {
        _logger.severe('网络请求异常: $error', error, stackTrace);
        // 网络请求异常
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('网络请求失败，请检查网络连接')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        _logger.info('登录流程结束');
      }
    } else {
      _logger.warning('表单验证失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.fine('构建登录页面UI');
    // 如果正在初始化（包括生成密钥对），显示加载指示器
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('用户登录'),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在初始化安全环境...'),
              SizedBox(height: 8),
              Text('这可能需要几秒钟时间'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户登录'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '数字资源管理',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // 用户名输入框（移除了登录方式选择）
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  if (value.length < 3) {
                    return '用户名至少3个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 密码输入框
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    return '密码至少6个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '登录',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 注册链接
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('还没有账户？立即注册'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
