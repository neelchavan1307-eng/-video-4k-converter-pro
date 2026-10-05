import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
  File? inputFile;
  String status = "Video Nivda - Khara 4K hoil";
  double progress = 0;
  bool isConverting = false;
  String selRes = "3840x2160";

  List<String> resolutions = [
    "3840x2160 (4K UHD)",
    "4096x2160 (DCI 4K)",
    "2560x1440 (2K QHD)",
    "1920x1080 (Full HD)",
  ];

  Future<void> pickVideo() async {
    await Permission.storage.request();
    await Permission.videos.request();
    await Permission.manageExternalStorage.request();
    FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r!= null && r.files.single.path!= null) {
      setState(() {
        inputFile = File(r.files.single.path!);
        status = "Selected: " + r.files.single.name;
        progress = 0;
      });
    }
  }

  Future<void> convertReal4K() async {
    if (inputFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adhi Video Nivda")));
      return;
    }
    setState(() {
      isConverting = true;
      status = "Khara 4K Conversion chalu ahe... 2-3 min lagel";
      progress = 0.1;
    });

    try {
      Directory movies = Directory("/storage/emulated/0/Movies/4KConverterPro");
      if (!await movies.exists()) {
        await movies.create(recursive: true);
      }
      Directory dcim = Directory("/storage/emulated/0/DCIM/4KConverterPro");
      if (!await dcim.exists()) {
        await dcim.create(recursive: true);
      }

      String outName = "REAL_4K_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";
      String outPath = movies.path + "/" + outName;

      String width = selRes.split("x")[0];
      String height = selRes.split("x")[1];

      // Khara 4K Upscaling Command - Lanczos filter
      String cmd = "-i " + inputFile!.path + " -vf scale=" + width + ":" + height + ":flags=lanczos -c:v libx264 -preset ultrafast -crf 20 -c:a aac -b:a 128k " + outPath;

      await FFmpegKit.execute(cmd).then((session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          try {
            await File(outPath).copy(dcim.path + "/" + outName);
            await File(outPath).copy("/storage/emulated/0/Download/" + outName);
          } catch (_) {}
          setState(() {
            status = "SUCCESS! Khara " + selRes + " Video banla!\n" + outPath;
            progress = 1.0;
            isConverting = false;
          });
        } else {
          final logs = await session.getAllLogsAsString();
          setState(() {
            status = "Failed: " + logs.toString().substring(0, 200);
            isConverting = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        status = "Error: " + e.toString();
        isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Real 4K Converter", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepPurple, width: 2),
              ),
              child: inputFile == null
                 ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, size: 50, color: Colors.grey),
                        SizedBox(height: 5),
                        Text("Video Nivda"),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 40, color: Colors.green),
                        const SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(inputFile!.path.split('/').last, textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
              child: DropdownButton<String>(
                value: selRes,
                isExpanded: true,
                dropdownColor: Color(0xFF1E1E1E),
                underline: SizedBox(),
                items: resolutions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) {
                  setState(() {
                    selRes = v!;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey[800], color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: pickVideo,
                icon: Icon(Icons.folder_open),
                label: Text("VIDEO NIVDA"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: isConverting? null : convertReal4K,
                icon: isConverting
                   ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.hd),
                label: Text(isConverting? "4
