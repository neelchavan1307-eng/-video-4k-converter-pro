import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '4K Converter Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A)),
      ),
      home: const ConverterScreen(),
    );
  }
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});
  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  File? _inputFile;
  String _status = "Video निवडा";
  double _progress = 0;
  bool _isConverting = false;
  String _savedPath = "";

  // Wikipedia नुसार 4K SETTINGS
  String _selectedResolution = "3840x2160 (4K UHD)";
  String _selectedFps = "30 FPS";
  String _selectedCodec = "H.265 / HEVC";
  String _selectedBitrate = "50 Mbps";
  String _selectedQuality = "High Quality";

  final List<String> _resolutions = [
    "3840x2160 (4K UHD - TV/Youtube)", // 8.3 MP - Main
    "4096x2160 (DCI 4K - Cinema Full)", // 8.8 MP - Cinema
    "3996x2160 (DCI Flat - 1.85:1)",
    "4096x1716 (CinemaScope - 2.39:1)",
    "3840x2400 (WQUXGA - 16:10)",
    "3840x1600 (UW-QHD+ Ultrawide)",
    "3840x1080 (DFHD - 32:9 Gaming)",
    "2560x1440 (2K QHD)",
    "1920x1080 (Full HD)",
  ];

  final List<String> _fpsList = ["24 FPS - Cinema", "30 FPS - Standard", "60 FPS - Smooth"];
  final List<String> _codecList = ["H.264", "H.265 / HEVC"];
  final List<String> _bitrateList = ["20 Mbps", "50 Mbps", "80 Mbps", "100 Mbps"];
  final List<String> _qualityList = ["Standard", "High Quality", "Maximize Quality"];

  Future<void> _pickVideo() async {
    await Permission.storage.request();
    await Permission.videos.request();
    await Permission.manageExternalStorage.request();
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _inputFile = File(result.files.single.path!);
        _status = "Selected: ${result.files
