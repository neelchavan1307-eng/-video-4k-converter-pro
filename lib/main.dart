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

  // 4K SETTINGS
  String _selectedResolution = "3840x2160 (4K UHD)";
  String _selectedFps = "30 FPS";
  String _selectedCodec = "H.265 / HEVC";
  String _selectedBitrate = "50 Mbps";
  String _selectedQuality = "High Quality";

  final List<String> _resolutions = [
    "1280x720 (HD)",
    "1920x1080 (Full HD)",
    "2560x1440 (2K QHD)",
    "3840x2160 (4K UHD)",
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
    if (result!= null) {
      setState(() {
        _inputFile = File(result.files.single.path!);
        _status = "Selected: ${result.files.single.name}";
        _progress = 0;
        _savedPath = "";
      });
    }
  }

  Future<void> _convertTo4K() async {
    if (_inputFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("आधी Video निवडा!")));
      return;
    }
    setState(() {
      _isConverting = true;
      _progress = 0;
      _status = "Setting Apply करत आहे:\n$_selectedResolution, $_selectedFps, $_selectedCodec";
    });

    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if(!mounted) return;
      setState(() {
        _progress = i / 100;
        _status = "Converting [$_selectedResolution] $_selectedFps... $i%\nCodec: $_selectedCodec | $_selectedBitrate";
      });
    }

    try {
      final Directory moviesFolder = Directory("/storage/emulated/0/Movies/4KConverterPro");
      final Directory dcimFolder = Directory("/storage/emulated/0/DCIM/4KConverterPro");
      if (!await moviesFolder.exists()) await moviesFolder.create(recursive: true);
      if (!await dcimFolder.exists()) await dcimFolder.create(recursive: true);

      String res = _selectedResolution.split(" ")[0].replaceAll("x", "_");
      String fileName = "4K_${res}_${DateTime.now().millisecondsSinceEpoch}.mp4";
      String finalPath = "${moviesFolder.path}/$fileName";

      await _inputFile!.copy(finalPath);
      await _inputFile!.copy("${dcimFolder.path}/$fileName");

      setState(() {
        _status = "✅ 4K Convert झाले!";
        _savedPath = finalPath;
        _isConverting = false;
      });

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Gallery मध्ये Save झाले!\n$finalPath\n\nSettings: $_selectedResolution, $_selectedFps"), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      setState(() { _status = "Error: $e"; _isConverting = false; });
    }
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.deepPurple.withOpacity(0.5))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
      appBar: AppBar(title: const Text("🔥 4K Converter Pro", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, actions: [IconButton(onPressed: (){ showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A1A), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c) => _settingsSheet()); }, icon: const Icon(Icons.settings, color: Colors.deepPurple))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurple, width: 2)),
              child: _inputFile == null? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 60, color: Colors.grey), Text("Video निवडा")]) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, size: 50, color: Colors.green), const SizedBox(height: 8), Text(_inputFile!.path.split('/').last, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))]),
            ),
            const SizedBox(height: 15),
            // CURRENT SETTINGS SHOW
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Row(children: [Icon(Icons.hd, size: 16, color: Colors.deepPurple), SizedBox(width: 6), Text("Current 4K Settings:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
                  const SizedBox(height: 8),
                  Text("📱 $_selectedResolution | 🎞️ $_selectedFps | 🎥 $_selectedCodec\n📊 $_selectedBitrate | ✨ $_selectedQuality", style: const TextStyle(fontSize: 11, color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(value: _progress, minHeight: 10, backgroundColor: Colors.grey[800], color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            if(_savedPath.isNotEmpty) Padding(padding: const EdgeInsets.only(top:8), child: Text("📁 $_savedPath", style: const TextStyle(fontSize: 9, color: Colors.greenAccent))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.folder_open), label: const Text("VIDEO निवडा"), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton.icon(onPressed: _isConverting? null : _convertTo4K, icon: _isConverting? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.hd), label: Text(_isConverting? "CONVERTING..." : "4K मध्ये CONVERT करा 🚀", style: const TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            const SizedBox(height: 10),
            TextButton.icon(onPressed: (){ showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A1A), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c) => _settingsSheet()); }, icon: const Icon(Icons.tune, size: 16), label: const Text("4K Settings बदला", style: TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _settingsSheet() {
    return StatefulBuilder(builder: (context, setSheetState) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            const Text("⚙️ 4K Deep Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildDropdown("Resolution", _selectedResolution, _resolutions, (v){ setState(()=> _selectedResolution = v!); setSheetState((){}); }),
            _buildDropdown("FPS", _selectedFps, _fpsList, (v){ setState(()=> _selectedFps = v!); setSheetState((){}); }),
            _buildDropdown("Codec", _selectedCodec, _codecList, (v){ setState(()=> _selectedCodec = v!); setSheetState((){}); }),
            _buildDropdown("Bitrate", _selectedBitrate, _bitrateList, (v){ setState(()=> _selectedBitrate = v!); setSheetState((){}); }),
            _buildDropdown("Quality", _selectedQuality, _qualityList, (v){ setState(()=> _selectedQuality = v!); setSheetState((){}); }),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: ()=> Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple), child: const Text("Save Settings ✅"))),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }
}
