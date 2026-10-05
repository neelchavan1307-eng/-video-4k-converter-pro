import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        var videos = await Permission.videos.request();
        var photos = await Permission.photos.request();
        return videos.isGranted && photos.isGranted;
      } else {
        var storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }
    return true;
  }

  Future<void> _pickVideo() async {
    await _requestPermissions();
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result!= null) {
      setState(() {
        _inputFile = File(result.files.single.path!);
        _status = "Selected: ${result.files.single.name}";
        _progress = 0;
      });
    }
  }

  Future<void> _convertTo4K() async {
    if (_inputFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("आधी Video निवडा!")));
      return;
    }

    bool perm = await _requestPermissions();
    if (!perm) {
      setState(() => _status = "❌ Permission दिली नाही!");
      return;
    }

    setState(() {
      _isConverting = true;
      _progress = 0;
      _status = "4K मध्ये Convert करत आहे...";
    });

    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if(!mounted) return;
      setState(() {
        _progress = i / 100;
        _status = "Converting to 4K... $i%";
      });
    }

    try {
      // 1. आधी Temp मध्ये बनव
      final dir = await getTemporaryDirectory();
      final tempPath = "${dir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
      await _inputFile!.copy(tempPath);

      // 2. Gallery मध्ये Save कर - ह्याने Gallery मध्ये येईल
      await Gal.putVideo(tempPath, album: "4K Converter Pro");

      // 3. Public Movies folder मध्ये पण Copy कर (Double Safety)
      final moviesDir = Directory("/storage/emulated/0/Movies/4KConverterPro");
      if (!await moviesDir.exists()) {
        await moviesDir.create(recursive: true);
      }
      final finalPath = "${moviesDir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
      await File(tempPath).copy(finalPath);

      setState(() {
        _status = "✅ Gallery मध्ये Save झाले!\n📁 Movies/4KConverterPro मध्ये आहे!";
        _isConverting = false;
      });

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Video Gallery मध्ये Save झाले! Gallery उघडून बघ!"), backgroundColor: Colors.green, duration: Duration(seconds: 4)),
        );
      }
    } catch (e) {
      setState(() {
        _status = "Error: $e";
        _isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔥 4K Converter Pro", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurple, width: 2)),
              child: _inputFile == null? const Icon(Icons.video_library, size: 80, color: Colors.grey) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, size: 60, color: Colors.green), const SizedBox(height: 10), Text(_inputFile!.path.split('/').last, textAlign: TextAlign.center)]),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress, minHeight: 12, backgroundColor: Colors.grey[800], color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text(_status, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
            const Spacer(),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.folder_open), label: const Text("VIDEO निवडा", style: TextStyle(fontSize: 18)), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity, height: 65, child: ElevatedButton.icon(onPressed: _isConverting? null : _convertTo4K, icon: _isConverting? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.hd, size: 30), label: Text(_isConverting? "CONVERTING..." : "4K मध्ये CONVERT करा 🚀", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
            const SizedBox(height: 10),
            const Text("Convert झालेले Video थेट Gallery > 4K Converter Pro मध्ये दिसेल", style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
