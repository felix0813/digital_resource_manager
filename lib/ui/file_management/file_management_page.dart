// lib/ui/file_management/file_management_page.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../logic/file_service.dart';
import '../../models/file_item.dart'; // 修改导入

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
  List<FileWithVersions> _files = []; // 修改类型
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
      // 使用新的方法获取文件和版本信息
      final files = await _fileService.listFilesWithVersionsWithAuth();
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

  Future<void> _downloadFile(FileWithVersions file) async {
    try {
      // 下载最新版本
      final response = await _fileService.downloadFileWithAuth(file.objectName);
      if (response != null && response.statusCode == 200) {
        final downloadDir = await _getDownloadDirectory();
        if (downloadDir != null) {
          final resourceManagerDirPath = path.join(downloadDir.path, 'ResourceManager');
          final resourceManagerDir = Directory(resourceManagerDirPath);

          if (!await resourceManagerDir.exists()) {
            await resourceManagerDir.create(recursive: true);
          }

          final filePath = path.join(resourceManagerDir.path, file.objectName);
          final fileToSave = File(filePath);

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
      return await getDownloadsDirectory();
    } catch (e) {
      debugPrint('获取下载目录时出错: $e');
      return null;
    }
  }

  Future<void> _deleteFile(FileWithVersions file) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除文件 "${file.objectName}" 吗？\n这将删除所有版本。'),
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
        final response = await _fileService.deleteFileWithAuth(file.objectName);
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

  Future<void> _showFileVersions(FileWithVersions file) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${file.objectName} 的版本',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('共 ${file.versions.length} 个版本'),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: file.versions.length,
                  itemBuilder: (context, index) {
                    final version = file.versions[index];
                    final isLatest = version.versionId == file.latestVersion;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          version.versionId,
                          style: TextStyle(
                            fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('大小: ${version.size} 字节'),
                            Text('时间: ${version.timestamp}'),
                            if (isLatest)
                              const Text(
                                '最新版本',
                                style: TextStyle(color: Colors.green),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            try {
                              final response = await _fileService.downloadFileWithAuth(
                                file.objectName,
                                versionId: version.versionId,
                              );
                              if (response != null && response.statusCode == 200) {
                                final downloadDir = await _getDownloadDirectory();
                                if (downloadDir != null) {
                                  final resourceManagerDirPath = path.join(
                                    downloadDir.path,
                                    'ResourceManager',
                                  );
                                  final resourceManagerDir = Directory(resourceManagerDirPath);

                                  if (!await resourceManagerDir.exists()) {
                                    await resourceManagerDir.create(recursive: true);
                                  }

                                  // 为版本文件添加版本ID后缀
                                  final fileNameWithoutExt = path.basenameWithoutExtension(file.objectName);
                                  final fileExt = path.extension(file.objectName);
                                  final versionFileName =
                                      '$fileNameWithoutExt-v${version.versionId}$fileExt';

                                  final filePath = path.join(resourceManagerDir.path, versionFileName);
                                  final fileToSave = File(filePath);

                                  await fileToSave.writeAsBytes(response.bodyBytes);

                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('文件已保存到: $filePath')),
                                    );
                                  }
                                }
                              } else if (response != null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('下载失败: ${response.body}')),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('下载出错: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('下载'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _loadMarkdownContent(FileWithVersions file) async {
    final response = await _fileService.downloadFileWithAuth(file.objectName);
    if (response == null) {
      throw Exception('无法下载文件');
    }
    if (response.statusCode != 200) {
      throw Exception('下载失败: ${response.body}');
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<void> _showMarkdownPreview(FileWithVersions file) async {
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool hideSource = false;
        bool hideRender = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(child: Text('Markdown 预览 - ${file.objectName}')),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        hideSource = !hideSource;
                        if (hideSource) {
                          hideRender = false;
                        }
                      });
                    },
                    child: Text(hideSource ? '显示原文件' : '隐藏原文件'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        hideRender = !hideRender;
                        if (hideRender) {
                          hideSource = false;
                        }
                      });
                    },
                    child: Text(hideRender ? '显示渲染' : '隐藏渲染'),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width * 0.8,
                height: MediaQuery.of(dialogContext).size.height * 0.7,
                child: FutureBuilder<String>(
                  future: _loadMarkdownContent(file),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('加载失败: ${snapshot.error}'));
                    }
                    final content = snapshot.data ?? '';
                    if (hideSource) {
                      return _buildMarkdownRenderPanel(content);
                    }
                    if (hideRender) {
                      return _buildMarkdownSourcePanel(content);
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 900;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildMarkdownSourcePanel(content),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMarkdownRenderPanel(content),
                              ),
                            ],
                          );
                        }
                        return DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              const TabBar(
                                tabs: [
                                  Tab(text: '原文件'),
                                  Tab(text: '渲染预览'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildMarkdownSourcePanel(content),
                                    _buildMarkdownRenderPanel(content),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('关闭'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMarkdownSourcePanel(String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownRenderPanel(String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Scrollbar(
        child: Markdown(
          data: content,
        ),
      ),
    );
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
        final fileExtension = path.extension(file.objectName).toLowerCase();
        final isMarkdown = fileExtension == '.md' || fileExtension == '.markdown';
        final menuItems = <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'download',
            child: Text('下载最新版本'),
          ),
          const PopupMenuItem<String>(
            value: 'versions',
            child: Text('查看所有版本'),
          ),
          if (isMarkdown)
            const PopupMenuItem<String>(
              value: 'preview',
              child: Text('Markdown 预览'),
            ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('删除所有版本'),
          ),
        ];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            title: Text(file.objectName),
            subtitle: Text('版本数: ${file.versions.length}'),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('大小: ${file.size} 字节'),
                        Text('最新版本: ${file.latestVersion}'),
                        Text('更新时间: ${file.timestamp}'),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String action) {
                      switch (action) {
                        case 'download':
                          _downloadFile(file);
                          break;
                        case 'versions':
                          _showFileVersions(file);
                          break;
                        case 'preview':
                          _showMarkdownPreview(file);
                          break;
                        case 'delete':
                          _deleteFile(file);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => menuItems,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
