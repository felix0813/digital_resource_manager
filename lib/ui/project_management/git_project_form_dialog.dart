// lib/ui/git_management/git_project_form_dialog.dart
import 'package:flutter/material.dart';
import '../../models/git_project.dart';

class GitProjectFormDialog extends StatefulWidget {
  final GitProject? project;
  final Function(GitProject) onSave;

  const GitProjectFormDialog({
    super.key,
    this.project,
    required this.onSave,
  });

  @override
  State<GitProjectFormDialog> createState() => _GitProjectFormDialogState();
}

class _GitProjectFormDialogState extends State<GitProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _accessTokenController;
  late TextEditingController _descriptionController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.project != null;

    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _urlController = TextEditingController(text: widget.project?.url ?? '');
    _usernameController = TextEditingController(text: widget.project?.username ?? '');
    _accessTokenController = TextEditingController(text: widget.project?.accessToken ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _accessTokenController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      final project = GitProject(
        id: widget.project?.id ?? 0,
        ownerId: widget.project?.ownerId ?? 0,
        name: _nameController.text,
        url: _urlController.text,
        username: _usernameController.text,
        accessToken: _accessTokenController.text,
        description: _descriptionController.text,
        createdAt: widget.project?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(project).then((value) {
        if (value) {
          Navigator.of(context).pop();
        }
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑项目' : '添加项目'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '项目名称 *',
                    hintText: '请输入项目名称',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入项目名称';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: '仓库地址 *',
                    hintText: 'https://github.com/user/repo.git',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入仓库地址';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    hintText: '用于HTTPS认证的用户名',
                  ),
                ),
                TextFormField(
                  controller: _accessTokenController,
                  decoration: const InputDecoration(
                    labelText: '访问令牌',
                    hintText: '用于HTTPS认证的访问令牌',
                  ),
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '描述',
                    hintText: '项目的描述信息',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveProject,
          child: Text(_isEditing ? '更新' : '创建'),
        ),
      ],
    );
  }
}
