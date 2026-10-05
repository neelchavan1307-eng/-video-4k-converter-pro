import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '4K Converter Pro',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const ConverterHome(),
    );
  }
}

class ConverterHome extends StatefulWidget {
  const ConverterHome({super.key});
  @override
  State<ConverterHome> createState() => _ConverterHomeState();
}

class _ConverterHomeState extends State<ConverterHome> {
  VideoPlayerController? _controller;
  File? _inputFile;
  File? _outputFile;
  bool _isConverting = false;
  double _progress = 0;
  String _status = 'Ready';
  double _sharp = 1.5, _color = 1.4, _contrast = 1.15;

  Future<void> pick() async {
    final v = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (v == null) return;
    _inputFile = File(v.path);
    await _controller?.dispose();
    _controller = VideoPlayerController.file(_inputFile!);
    await _controller!.initialize();
    _controller!.setLooping(true);
    _controller!.play();
    setState(() { _outputFile = null; _status = 'Loaded: ${v.path.split('.').last.toUpperCase()}'; });
  }

  Future<void> convert() async {
    if (_inputFile == null) return;
    setState(() { _isConverting = true; _progress = 0.3; _status = '4K Engine सुरू...'; });
    final dir = await getTemporaryDirectory();
    final out = '${dir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final cmd = "-i '${_inputFile!.path}' -vf scale=3840:2160:flags=lanczos:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2:color=black,unsharp=5:5:$_sharp:5:5:0.8,eq=contrast=$_contrast:brightness=0.06:saturation=$_color -c:v libx264 -preset fast -crf 17 -c:a aac -b:a 192k $out";
    setState(() { _progress = 0.6; _status = 'Clarity & Color Boost करत आहे...'; });
    await FFmpegKit.execute(cmd).then((s) async {
      final code = await s.getReturnCode();
      if (ReturnCode.isSuccess(code)) {
        setState(() { _outputFile = File(out); _isConverting = false; _progress = 1; _status = '4K मध्ये तयार! 🔥 Amazing Clarity'; });
      } else {
        setState(() { _isConverting = false; _status = 'Error, परत प्रयत्न करा'; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('4K CONVERTER PRO 🚀', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.black, centerTitle: true),
      body: _inputFile == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.hd, size: 110, color: Colors.white12),
              const Text('MP4 / 3GP / HD', style: TextStyle(color: Colors.white54)),
              const Text('TO 4K ULTRA HD', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('कितीही Zoom करा - फाटणार नाही!', style: TextStyle(color: Colors.amber)),
              const SizedBox(height: 28),
              ElevatedButton.icon(onPressed: pick, icon: const Icon(Icons.video_file), label: const Text('VIDEO निवडा'), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16))),
            ]))
          : ListView(padding: const EdgeInsets.all(14), children: [
              ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: _controller?.value.aspectRatio ?? 16/9, child: _controller!=null && _controller!.value.isInitialized ? VideoPlayer(_controller!) : Container(color: Colors.white10))),
              const SizedBox(height: 10),
              Row(children: [Chip(label: Text(_inputFile!.path.split('.').last.toUpperCase())), const SizedBox(width: 6), const Chip(label: Text('→ 4K'), backgroundColor: Colors.amber), const Spacer(), IconButton(onPressed: pick, icon: const Icon(Icons.change_circle, color: Colors.white))]),
              Card(color: Colors.white10, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                Text('SHARPNESS: ${_sharp.toStringAsFixed(1)} - Zoom फाटणार नाही', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Slider(value: _sharp, min: 0.5, max: 3, activeColor: Colors.amber, onChanged: (v) => setState(() => _sharp = v)),
                Text('COLOR: ${_color.toStringAsFixed(1)} - एक नंबर कलर', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Slider(value: _color, min: 0.8, max: 2.5, activeColor: Colors.amber, onChanged: (v) => setState(() => _color = v)),
              ]))),
              if (_isConverting) LinearProgressIndicator(value: _progress, color: Colors.amber),
              if (_isConverting) Padding(padding: const EdgeInsets.all(8), child: Text(_status, style: const TextStyle(color: Colors.amber), textAlign: TextAlign.center)),
              if (!_isConverting && _outputFile == null) ElevatedButton.icon(onPressed: convert, icon: const Icon(Icons.rocket_launch), label: const Text('4K मध्ये CONVERT करा'), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 56))),
              if (_outputFile != null) Card(color: Colors.green.shade900, child: ListTile(title: const Text('4K Ready! 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text(_status, style: const TextStyle(color: Colors.white70)), trailing: IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () => Share.shareXFiles([XFile(_outputFile!.path)])))),
            ]),
    );
  }
}
