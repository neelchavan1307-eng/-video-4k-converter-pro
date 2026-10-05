import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';

void main() { runApp(const MyApp()); }

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? inputPath;
  String status = "Select a video";
  bool isConverting = false;
  String? outputPath;

  Future<void> pickVideo() async {
    await Permission.storage.request();
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        inputPath = result.files.single.path;
        status = "Selected: ${result.files.single.name}";
        outputPath = null;
      });
    }
  }

  Future<void> convertTo4K() async {
    if (inputPath == null) { setState(() => status = "Please select video first"); return; }
    setState(() { isConverting = true; status = "Converting to 4K..."; });
    final dir = await getExternalStorageDirectory();
    final outDir = Directory("${dir!.path}/4K_Videos");
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final outPath = "${outDir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    final command = "-i \"$inputPath\" -vf scale=3840:2160:flags=lanczos -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k \"$outPath\"";
    FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() { isConverting = false; status = "Success! Saved"; outputPath = outPath; });
      } else {
        setState(() { isConverting = false; status = "Failed"; });
      }
    }, (log) {}, (Statistics stats) {
      setState(() { status = "Converting ${stats.getProgress()}%"; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Real 4K Converter Pro")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (isConverting) const LinearProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: pickVideo, child: const Text("Select Video")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: isConverting ? null : convertTo4K, child: Text(isConverting ? "Converting..." : "Convert to 4K")),
            const SizedBox(height: 20),
            if (outputPath != null) Text(outputPath!, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
