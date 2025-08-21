// lib/ui/register/register_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/environment.dart';
import 'package:logging/logging.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false; // 添加加载状态
  final Logger _logger = Logger('RegisterPage'); // 创建日志记录器

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 构造符合要求的请求体
        final registerData = {
          'username': _usernameController.text,
          'password': _passwordController.text,
          'email': _emailController.text,
        };

        _logger.info('开始注册请求，用户名: ${_usernameController.text}, 邮箱: ${_emailController.text}');

        // 执行注册网络请求
        final response = await http.post(
          Uri.parse(Environment.registerUrl), // 使用环境变量配置的URL
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(registerData),
        );

        _logger.info('注册响应状态码: ${response.statusCode}');
        _logger.fine('注册响应体: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          _logger.info('用户注册成功，用户名: ${_usernameController.text}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('注册成功')),
            );
            Navigator.pop(context); // 返回登录页面
          }
        } else {
          _logger.warning('注册失败，状态码: ${response.statusCode}, 响应体: ${response.body}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('注册失败，请重试')),
            );
          }
        }
      } catch (e) {
        _logger.severe('注册过程中发生异常: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('网络请求失败')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.fine('构建注册页面UI');
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户注册'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _logger.fine('用户名验证失败：未输入用户名');
                    return '请输入用户名';
                  }
                  if (value.length < 3) {
                    _logger.fine('用户名验证失败：用户名长度不足');
                    return '用户名至少3个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _logger.fine('邮箱验证失败：未输入邮箱');
                    return '请输入邮箱';
                  }
                  // 简单的邮箱格式验证
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    _logger.fine('邮箱验证失败：邮箱格式不正确');
                    return '请输入有效的邮箱地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                    _logger.fine('密码验证失败：未输入密码');
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    _logger.fine('密码验证失败：密码长度不足');
                    return '密码至少6个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: '确认密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _logger.fine('确认密码验证失败：未确认密码');
                    return '请确认密码';
                  }
                  if (value != _passwordController.text) {
                    _logger.fine('确认密码验证失败：两次密码输入不一致');
                    return '两次输入的密码不一致';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register, // 添加加载状态控制
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          '注册',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _logger.fine('用户点击登录按钮，返回登录页面');
                  Navigator.pop(context);
                },
                child: const Text('已有账户？立即登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
