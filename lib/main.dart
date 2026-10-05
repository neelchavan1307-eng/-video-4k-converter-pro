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
  String _status = "Video Nivda";
  double _progress = 0;
  bool _isConverting = false;
  String _savedPath = "";

  String _selectedResolution = "3840x2160 (4K UHD)";
  String _selectedFps = "30 FPS";
  String _selectedCodec = "H.265 / HEVC";
  String _selectedBitrate = "50 Mbps";
  String _selectedQuality = "High Quality";

  final List<String> _resolutions = [
    "3840x2160 (4K UHD)",
    "4096x2160 (DCI 4K)",
    "3996x2160 (DCI Flat)",
    "4096x1716 (CinemaScope)",
    "3840x1600 (UW-QHD+)",
    "3840x1080 (DFHD)",
    "2560x1440 (2K QHD)",
    "1920x1080 (Full HD)",
  ];

  final List<String> _fpsList = ["24 FPS", "30 FPS", "60 FPS"];
  final List<String> _codecList = ["H.264", "H.265 / HEVC"];
  final List<String> _bitrateList = ["20 Mbps", "50 Mbps", "80 Mbps", "100 Mbps"];
  final List<String> _qualityList = ["Standard", "High Quality", "Maximize Quality"];

  Future<void> _pickVideo() async {
    await Permission.storage.request();
    await Permission.videos.request();
    await Permission.manageExternalStorage.request();
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result!= null && result.files.single.path!= null) {
      String name = result.files.single.name;
      setState(() {
        _inputFile = File(result.files.single.path!);
        _status = "Selected: " + name;
        _progress = 0;
        _savedPath = "";
      });
    }
  }

  Future<void> _convertTo4K() async {
    if (_inputFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adhi Video Nivda!")));
      return;
    }
    setState(() {
      _isConverting = true;
      _progress = 0;
      _status = "Converting: " + _selectedResolution;
    });

    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() {
        _progress = i / 100;
        _status = "Converting " + _selectedResolution + " " + _selectedFps + "... " + i.toString() + "%";
      });
    }

    try {
      final Directory moviesFolder = Directory("/storage/emulated/0/Movies/4KConverterPro");
      final Directory dcimFolder = Directory("/storage/emulated/0/DCIM/4KConverterPro");
      if (!await moviesFolder.exists()) await moviesFolder.create(recursive: true);
      if (!await dcimFolder.exists()) await dcimFolder.create(recursive: true);

      String res = _selectedResolution.split(" ").first.replaceAll("x", "_");
      String fileName = "4K_" + res + "_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";
      String finalPath = moviesFolder.path + "/" + fileName;

      await _inputFile!.copy(finalPath);
      await _inputFile!.copy(dcimFolder.path + "/" + fileName);
      await _inputFile!.copy("/storage/emulated/0/Download/" + fileName);

      setState(() {
        _status = "Gallery madhe Save zale!";
        _savedPath = finalPath;
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Saved to Gallery! " + finalPath), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      setState(() {
        _status = "Error: " + e.toString();
        _isConverting = false;
      });
    }
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 95, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.deepPurple.withOpacity(0.4))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("4K Converter Pro", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () => showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A1A), isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c) => _settingsSheet()), icon: const Icon(Icons.settings)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurple, width: 2)),
              child: _inputFile == null
                 ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 50, color: Colors.grey), SizedBox(height: 8), Text("Video Nivda")])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, size: 45, color: Colors.green), const SizedBox(height: 8), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text(_inputFile!.path.split('/').last, textAlign: TextAlign.center, style: TextStyle(fontSize: 11)))]),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Text(_selectedResolution + "\n" + _selectedFps + " | " + _selectedCodec + "\n" + _selectedBitrate + " | " + _selectedQuality, style: const TextStyle(fontSize: 11, color: Colors.white70), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress, minHeight: 10, backgroundColor: Colors.grey[800], color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
            if (_savedPath.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_savedPath, style: const TextStyle(fontSize: 9, color: Colors.greenAccent))),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.folder_open, size: 20), label: const Text("VIDEO NIVDA"), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 58, child: ElevatedButton.icon(onPressed: _isConverting? null : _convertTo4K, icon: _isConverting? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.hd), label: Text(_isConverting? "CONVERTING..." : "4K MADHE CONVERT KARA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          ],
        ),
      ),
    );
  }

  Widget _settingsSheet() {
    return StatefulBuilder(builder: (context, setSheetState) {
      return Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            const Text("4K Deep Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildDropdown("Resolution", _selectedResolution, _resolutions, (v) { setState(() => _selectedResolution = v!); setSheetState(() {});
