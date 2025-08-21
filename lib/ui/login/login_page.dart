// lib/ui/login/login_page.dart
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  // 登录方式：true表示使用邮箱，false表示使用用户名
  bool _useEmail = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // 构造登录请求体
      final loginData = {
        _useEmail ? 'email' : 'username': _identifierController.text,
        'password': _passwordController.text,
      };

      // 执行登录逻辑（这里可以添加网络请求）
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功')),
      );

      // 登录成功后返回主页
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // 登录方式选择
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('用户名'),
                      selected: !_useEmail,
                      onSelected: (selected) {
                        setState(() {
                          _useEmail = !selected;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('邮箱'),
                      selected: _useEmail,
                      onSelected: (selected) {
                        setState(() {
                          _useEmail = selected;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 用户名/邮箱输入框
              TextFormField(
                controller: _identifierController,
                decoration: InputDecoration(
                  labelText: _useEmail ? '邮箱' : '用户名',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_useEmail ? Icons.email : Icons.person),
                ),
                keyboardType: _useEmail ? TextInputType.emailAddress : TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _useEmail ? '请输入邮箱' : '请输入用户名';
                  }

                  if (_useEmail) {
                    // 邮箱格式验证
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return '请输入有效的邮箱地址';
                    }
                  } else {
                    // 用户名验证
                    if (value.length < 3) {
                      return '用户名至少3个字符';
                    }
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
                  onPressed: _login,
                  child: const Text(
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
