import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Real 4K Converter',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? inputPath;
  String status = "कोणताही Video Select करा";
  double progress = 0;
  bool isConverting = false;
  String? outputPath;

  Future<void> pickVideo() async {
    await Permission.storage.request();
    await Permission.videos.request();
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        inputPath = result.files.single.path;
        status = "Selected: ${result.files.single.name}";
        progress = 0;
        outputPath = null;
      });
    }
  }

  Future<void> convertTo4K() async {
    if (inputPath == null) {
      setState(() => status = "पहिला Video Select करा!");
      return;
    }

    setState(() {
      isConverting = true;
      status = "Converting to Real 4K...";
      progress = 0;
    });

    final dir = await getExternalStorageDirectory();
    final outDir = Directory("${dir!.path}/4K_V
