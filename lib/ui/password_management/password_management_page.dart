// 密码管理页面
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:logging/logging.dart';
import '../../models/password_item.dart';
import '../../logic/password_service.dart';

class PasswordManagementPage extends StatefulWidget {
  const PasswordManagementPage({super.key});

  @override
  State<PasswordManagementPage> createState() => _PasswordManagementPageState();
}

class _PasswordManagementPageState extends State<PasswordManagementPage> {
  List<PasswordItem> passwords = [];
  bool isLoading = false;
  final PasswordService _passwordService = PasswordService();
  final Logger _logger = Logger('PasswordManagementPage');

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  // 加载密码列表
  Future<void> _loadPasswords() async {
    _logger.info('开始加载密码列表');
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _passwordService.listPasswordsWithAuth();
      if (response != null) {
        _logger.info('收到密码列表响应，状态码: ${response.statusCode}');
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _logger.info('成功解析密码列表，共 ${data.length} 项密码');
          setState(() {
            passwords = data.map((item) => PasswordItem.fromJson(item)).toList();
          });
          _logger.info('密码列表加载完成，共 ${passwords.length} 项');
        } else {
          _logger.warning('加载密码列表失败，状态码: ${response.statusCode}, 响应体: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('加载密码失败')),
          );
        }
      } else {
        _logger.warning('加载密码列表失败，响应为空');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载密码失败')),
        );
      }
    } catch (e, stackTrace) {
      // 处理错误
      _logger.severe('加载密码列表时发生异常: $e', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加载密码失败')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
      _logger.info('密码列表加载流程结束，当前加载状态: $isLoading');
    }
  }

  // 创建新密码
  Future<bool> _createPassword(PasswordItem password) async {
    _logger.info('开始创建新密码，网站: ${password.website}, 用户名: ${password.userName}');
    try {
      final response = await _passwordService.createPasswordWithAuth(password);
      if (response != null) {
        _logger.info('收到创建密码响应，状态码: ${response.statusCode}');
        if (response.statusCode == 201) {
          _logger.info('密码创建成功');
          _loadPasswords(); // 重新加载列表
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码创建成功')),
          );
          return true;
        } else {
          _logger.warning('密码创建失败，状态码: ${response.statusCode}, 响应体: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码创建失败')),
          );
        }
      } else {
        _logger.warning('密码创建失败，响应为空');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建密码失败')),
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('创建密码时发生异常: $e', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建密码失败')),
      );
    }
    return false;
  }

  // 更新密码
  Future<bool> _updatePassword(PasswordItem password) async {
    _logger.info('开始更新密码，ID: ${password.id}, 网站: ${password.website}, 用户名: ${password.userName}');
    try {
      final response = await _passwordService.updatePasswordWithAuth(password);
      if (response != null) {
        _logger.info('收到更新密码响应，状态码: ${response.statusCode}');
        if (response.statusCode == 200) {
          _logger.info('密码更新成功');
          _loadPasswords(); // 重新加载列表
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码更新成功')),
          );
          return true;
        } else {
          _logger.warning('密码更新失败，状态码: ${response.statusCode}, 响应体: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码更新失败')),
          );
        }
      } else {
        _logger.warning('密码更新失败，响应为空');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新密码失败')),
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('更新密码时发生异常: $e', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新密码失败')),
      );
    }
    return false;
  }

  // 删除密码
  Future<void> _deletePassword(int id) async {
    _logger.info('开始删除密码，ID: $id');
    try {
      final response = await _passwordService.deletePasswordWithAuth(id);
      if (response != null) {
        _logger.info('收到删除密码响应，状态码: ${response.statusCode}');
        if (response.statusCode == 200) {
          _logger.info('密码删除成功');
          setState(() {
            passwords.removeWhere((password) => password.id == id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码删除成功')),
          );
        } else {
          _logger.warning('密码删除失败，状态码: ${response.statusCode}, 响应体: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码删除失败')),
          );
        }
      } else {
        _logger.warning('密码删除失败，响应为空');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除密码失败')),
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('删除密码时发生异常: $e', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除密码失败')),
      );
    }
  }

  // 获取单个密码明文
  Future<String?> _getPasswordPlaintext(int id) async {
    _logger.info('开始获取密码明文，ID: $id');
    try {
      final response = await _passwordService.getPasswordWithAuth(id);
      if (response != null) {
        _logger.info('收到获取密码明文响应，状态码: ${response.statusCode}');
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final password = data['password'] as String?;
          _logger.info('成功获取密码明文');
          return password;
        } else {
          _logger.warning('获取密码明文失败，状态码: ${response.statusCode}, 响应体: ${response.body}');
        }
      } else {
        _logger.warning('获取密码明文失败，响应为空');
      }
    } catch (e, stackTrace) {
      _logger.severe('获取密码明文时发生异常: $e', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('获取密码明文失败')),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('密码管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showPasswordDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : passwords.isEmpty
              ? const Center(
                  child: Text('暂无密码数据'),
                )
              :ListView.builder(
  itemCount: passwords.length,
  itemBuilder: (context, index) {
    final password = passwords[index];
    return ListTile(
      title: Text(password.website ?? '未命名网站'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(password.userName),
          Text('最后修改时间：${password.updatedAt.split("T")[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () async {
              final plaintext = await _getPasswordPlaintext(password.id);
              if (plaintext != null && context.mounted) {
                _showPlaintextPassword(plaintext);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showPasswordDialog(password: password),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deletePassword(password.id),
          ),
        ],
      ),
      onTap: () => _showPasswordDetail(password),
    );
  },
),

      floatingActionButton: FloatingActionButton(
        onPressed: _loadPasswords,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // 显示密码明文
  void _showPlaintextPassword(String password) {
    _logger.info('显示密码明文对话框');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('密码明文'),
          content: SelectableText(password),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  // 显示密码详情
  void _showPasswordDetail(PasswordItem password) {
    _logger.info('显示密码详情，ID: ${password.id}, 网站: ${password.website}');
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('网站: ${password.website ?? '未指定'}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('用户名: ${password.userName}'),
              const SizedBox(height: 8),
              const Text('密码: ******** (点击眼睛图标查看明文)'),
              const SizedBox(height: 8),
              Text('描述: ${password.description ?? '无描述'}'),
              const SizedBox(height: 16),
              Text('创建时间: ${password.createdAt.split("T")[0]}'),
              const SizedBox(height: 8),
              Text('更新时间: ${password.updatedAt.split("T")[0]}'),
            ],
          ),
        );
      },
    );
  }

  // 显示密码编辑对话框
  void _showPasswordDialog({PasswordItem? password}) {
    final isEditing = password != null;
    _logger.info('${isEditing ? '编辑' : '创建'}密码对话框');
    final websiteController = TextEditingController(text: password?.website ?? '');
    final usernameController = TextEditingController(text: password?.userName ?? '');
    final passwordController = TextEditingController(text: password?.password ?? '');
    final descriptionController = TextEditingController(text: password?.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? '编辑密码' : '添加密码'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(labelText: '网站'),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: '用户名'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: '密码'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: '描述'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final newPassword = PasswordItem(
                  id: password?.id ?? 0,
                  ownerId: password?.ownerId ?? 0, // 实际应用中应从用户信息中获取
                  userName: usernameController.text,
                  password: passwordController.text,
                  website: websiteController.text,
                  description: descriptionController.text,
                  createdAt: password?.createdAt ?? DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                );

                if (isEditing) {
                  _updatePassword(newPassword).then((success){
                    if (success) {
                      Navigator.of(context).pop();
                    }
                  });
                } else {
                  _createPassword(newPassword).then((success){
                    if (success) {
                      Navigator.of(context).pop();
                    }
                  });
                }


              },
              child: Text(isEditing ? '更新' : '添加'),
            ),
          ],
        );
      },
    );
  }
}
