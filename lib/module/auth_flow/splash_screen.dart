import 'package:account_manager/core/app_theme.dart';
import 'package:account_manager/module/auth_flow/unlock_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import '../service/database_controller.dart';

class SplashScreen extends StatefulWidget {
  static Database? database;
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    await _initDatabase();

    // Wait for at least 2 seconds for splash visibility
    await Future.delayed(const Duration(seconds: 2));

    // We always redirect to the UnlockScreen. It will determine if the app 
    // needs to set up a new password or prompt to unlock.
    Get.offAll(() => const UnlockScreen());
  }

  Future<void> _initDatabase() async {
    DatabaseController data = Get.put(DatabaseController());

    var databasesPath = await getDatabasesPath();
    String path = '$databasesPath/AccountManager.db';

    SplashScreen.database = await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE Account (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, credit TEXT, debit TEXT, balance TEXT, is_synced INTEGER DEFAULT 0, is_deleted INTEGER DEFAULT 0, updated_at INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE MyTransaction (id INTEGER PRIMARY KEY,date TEXT , AcId INTEGER, detail TEXT, credit TEXT, debit TEXT, is_synced INTEGER DEFAULT 0, is_deleted INTEGER DEFAULT 0, updated_at INTEGER DEFAULT 0)',
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE Account ADD COLUMN is_synced INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE Account ADD COLUMN is_deleted INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE Account ADD COLUMN updated_at INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE MyTransaction ADD COLUMN is_synced INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE MyTransaction ADD COLUMN is_deleted INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE MyTransaction ADD COLUMN updated_at INTEGER DEFAULT 0');
        }
      },
    );

    data.selectData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [MyColors.secondaryColor, MyColors.primaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset("assets/images/logo.png", height: 100, width: 100)),
                ),
                const SizedBox(height: 24),
                Text(
                  "Account Manager",
                  style: TextStyle(fontFamily: 'poppins_semi_bold', fontSize: 26, color: Colors.white, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
