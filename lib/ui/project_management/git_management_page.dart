// lib/ui/git_management/git_management_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../logic/git_project_service.dart';
import '../../models/git_project.dart';
import 'git_project_form_dialog.dart';

// 添加一个用于显示详细信息的小部件
class _DetailRow extends StatelessWidget {
  final String title;
  final String content;

  const _DetailRow({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class GitManagementPage extends StatefulWidget {
  const GitManagementPage({super.key});

  @override
  State<GitManagementPage> createState() => _GitManagementPageState();
}

class _GitManagementPageState extends State<GitManagementPage> {
  List<GitProject> _projects = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await GitProjectService().listProjectsWithAuth();

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _projects = data.map((json) => GitProject.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _errorMessage = '获取项目列表失败';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载项目时出错: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _createProject(GitProject project) async {
    try {
      final response = await GitProjectService().createProjectWithAuth(project);

      if (response != null && response.statusCode == 201) {
        // 刷新列表
        _loadProjects();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('项目创建成功')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('项目创建失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建项目时出错: $e')),
      );
    }
    return false;
  }

  Future<bool> _updateProject(GitProject project) async {
    try {
      final response = await GitProjectService().updateProjectWithAuth(project);

      if (response != null && response.statusCode == 200) {
        // 刷新列表
        _loadProjects();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('项目更新成功')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('项目更新失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新项目时出错: $e')),
      );
    }
    return false;
  }

  Future<void> _deleteProject(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这个项目吗？此操作不可撤销。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final response = await GitProjectService().deleteProjectWithAuth(id);

        if (response != null && response.statusCode == 200) {
          // 刷新列表
          _loadProjects();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('项目删除成功')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('项目删除失败')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除项目时出错: $e')),
        );
      }
    }
  }

  void _showProjectForm([GitProject? project]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GitProjectFormDialog(
          project: project,
          onSave: project == null ? _createProject : _updateProject,
        );
      },
    );
  }

  // 在 _GitManagementPageState 类中添加新的展示信息方法
  void _showProjectDetails(GitProject project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(project.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(title: '项目名称', content: project.name),
                _DetailRow(title: '项目URL', content: project.url),
                _DetailRow(
                    title: '项目描述',
                    content: project.description.isEmpty
                        ? '无'
                        : project.description),
                _DetailRow(
                    title: '项目创建时间',
                    content: project.createdAt.toString().split(".")[0]),
                _DetailRow(
                    title: '项目更新时间',
                    content: project.updatedAt.toString().split(".")[0]),
                // 根据privateKey是否存在来决定是否显示
                if (project.privateKey.isNotEmpty)
                  _DetailRow(title: '项目SSH密钥', content: project.privateKey),
                // 根据accessToken是否存在来决定是否显示
                if (project.accessToken.isNotEmpty)
                  _DetailRow(title: '项目访问令牌', content: project.accessToken),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Git项目管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProjects,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '暂无Git项目',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showProjectForm(),
                            child: const Text('添加项目'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(project.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.url,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.blue),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  project.description.isEmpty?'缺少项目描述':project.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '创建时间: ${project.createdAt.toString().split(".")[0]}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '更新时间: ${project.updatedAt.toString().split(".")[0]}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showProjectForm(project),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteProject(project.id),
                                ),
                              ],
                            ),
                            onTap: () => _showProjectDetails(project),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProjectForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
