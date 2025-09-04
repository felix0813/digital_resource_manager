import 'package:digital_resource_manager/ui/file_management/file_management_page.dart';
import 'package:digital_resource_manager/ui/login/login_page.dart';
import 'package:digital_resource_manager/ui/password_management/password_management_page.dart';
import 'package:digital_resource_manager/ui/project_management/project_management_page.dart';
import 'package:digital_resource_manager/ui/register/register_page.dart';
import 'package:digital_resource_manager/ui/setting/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

void main() {
  // 配置日志
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record
        .message}');
    if (record.error != null) {
      print('${record.level.name}: ${record.time}: ${record
          .loggerName}: 错误详情: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('${record.level.name}: ${record.time}: ${record
          .loggerName}: 堆栈跟踪:\n${record.stackTrace}');
    }
  });
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '数字资源管理'),
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(), // 添加登录页面路由
      },
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  // 页面控制器
  final List<Widget> _pages = [
    const PasswordManagementPage(),
    const FileManagementPage(),
    const ProjectManagementPage(),
    const SettingPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lock),
            label: '密码管理',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_present),
            label: '文件管理',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: '项目管理',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

