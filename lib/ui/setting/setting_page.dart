// lib/ui/setting/setting_page.dart
import 'package:digital_resource_manager/ui/register/register_page.dart';
import 'package:digital_resource_manager/ui/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isLoggedIn = false;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final username = prefs.getString('username');

    setState(() {
      _isLoggedIn = accessToken != null && accessToken.isNotEmpty;
      _username = username ?? '';
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 清除用户相关的所有数据
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('expires_in');
    await prefs.remove('device_id_db');
    await prefs.remove('last_login_at');

    setState(() {
      _isLoggedIn = false;
      _username = '';
    });

    // 显示退出登录成功的提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已退出登录')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设置',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 显示当前用户信息（如果已登录）
            if (_isLoggedIn) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('当前用户'),
                  subtitle: Text(_username),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 根据登录状态显示不同的按钮
            if (!_isLoggedIn) ...[
              // 未登录时显示登录和注册按钮
              Card(
                child: ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('用户登录'),
                  subtitle: const Text('登录现有账户'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    ).then((_) => _checkLoginStatus()); // 返回后刷新登录状态
                  },
                ),
              ),
              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.app_registration),
                  title: const Text('用户注册'),
                  subtitle: const Text('创建新账户'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    ).then((_) => _checkLoginStatus()); // 返回后刷新登录状态
                  },
                ),
              ),
              const SizedBox(height: 10),
            ] else ...[
              // 已登录时显示退出登录按钮
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('退出登录'),
                  subtitle: const Text('注销当前账户'),
                  onTap: _logout,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 关于按钮
            Card(
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text('关于应用'),
                subtitle: const Text('版本信息'),
                onTap: () {
                  // 关于页面逻辑
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
