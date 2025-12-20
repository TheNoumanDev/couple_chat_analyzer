import 'package:flutter/material.dart';
import 'core/app.dart';
import 'core/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies (no Hive, using in-memory storage)
  await initDependencies();
  
  runApp(const ChatInsightApp());
}