// main.dart
// Updated main file for optimized structure

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/app.dart';
import 'core/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize dependencies
  await initDependencies();
  
  runApp(const ChatInsightApp());
}