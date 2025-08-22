// lib/ui/file_management/file_management_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../logic/file_service.dart';
import '../../models/file_item.dart';

class FileManagementPage extends StatelessWidget {
  const FileManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FileManagementView();
  }
}

class FileManagementView extends StatefulWidget {
  const FileManagementView({super.key});

  @override
  State<FileManagementView> createState() => _FileManagementViewState();
}

class _FileManagementViewState extends State<FileManagementView> {
  late FileService _fileService;
  List<FileItem> _files = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fileService = FileService();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final files = await _fileService.listBucketObjectsWithAuth();
      if (files != null) {
        setState(() {
          _files = files;
        });
      } else {
        setState(() {
          _errorMessage = '加载文件列表失败';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载文件列表失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      try {
        final response = await _fileService.uploadFileWithAuth(file);
        if (response != null && response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件上传成功')),
          );
          _loadFiles(); // 重新加载文件列表
        } else if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传失败: ${response.body}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('上传失败')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传出错: $e')),
        );
      }
    }
  }

  Future<void> _downloadFile(FileItem file) async {
  try {
    final response = await _fileService.downloadFileWithAuth(file.name);
    if (response != null && response.statusCode == 200) {
      // 获取平台特定的下载目录
      final downloadDir = await _getDownloadDirectory();
      if (downloadDir != null) {
        // 使用path.join创建ResourceManager子目录路径
        final resourceManagerDirPath = path.join(downloadDir.path, 'ResourceManager');
        final resourceManagerDir = Directory(resourceManagerDirPath);

        if (!await resourceManagerDir.exists()) {
          await resourceManagerDir.create(recursive: true);
        }

        // 使用path.join创建文件路径
        final filePath = path.join(resourceManagerDir.path, file.name);
        final fileToSave = File(filePath);

        // 写入文件内容
        await fileToSave.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件已保存到: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法获取下载目录')),
        );
      }
    } else if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: ${response.body}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载失败')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('下载出错: $e')),
    );
  }
}

  Future<Directory?> _getDownloadDirectory() async {
    try {
      // 使用 path_provider 提供的 getDownloadsDirectory 方法
      return await getDownloadsDirectory();
    } catch (e) {
      debugPrint('获取下载目录时出错: $e');
      return null;
    }
  }

  Future<void> _deleteFile(FileItem file) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除文件 "${file.name}" 吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('删除'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final response = await _fileService.deleteFileWithAuth(file.name);
        if (response != null && response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件删除成功')),
          );
          _loadFiles(); // 重新加载文件列表
        } else if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: ${response.body}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除失败')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除出错: $e')),
        );
      }
    }
  }

  Future<void> _showFileVersions(FileItem file) async {
    try {
      final response = await _fileService.listFileVersionsWithAuth(file.name);
      if (response != null && response.statusCode == 200) {
        // 解析版本信息并在对话框中显示
        // 这里简化处理，实际应用中需要解析返回的版本数据
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('${file.name} 的版本'),
              content: Text(response.body),
              actions: <Widget>[
                TextButton(
                  child: const Text('关闭'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      } else if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取版本信息失败: ${response.body}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取版本信息失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取版本信息出错: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '文件管理',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _uploadFile,
                  icon: const Icon(Icons.upload),
                  label: const Text('上传文件'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _loadFiles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新列表'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red))
            else
              Expanded(
                child: _files.isEmpty
                    ? const Center(child: Text('暂无文件'))
                    : _buildFileList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(file.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('大小: ${file.size} 字节'),
                Text('版本ID: ${file.versionId ?? "N/A"}'),
                Text('更新时间: ${file.lastModified?.toString() ?? "N/A"}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String action) {
                switch (action) {
                  case 'download':
                    _downloadFile(file);
                    break;
                  case 'versions':
                    _showFileVersions(file);
                    break;
                  case 'delete':
                    _deleteFile(file);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'download',
                  child: Text('下载'),
                ),
                const PopupMenuItem<String>(
                  value: 'versions',
                  child: Text('查看版本'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('删除'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
