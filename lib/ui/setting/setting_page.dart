// lib/ui/setting/setting_page.dart
import 'package:digital_resource_manager/ui/register/register_page.dart';
import 'package:digital_resource_manager/ui/login/login_page.dart'; // 添加导入
import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

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

            // 登录按钮
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
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // 注册按钮
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
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

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
