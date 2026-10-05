import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  String status = "Video Nivda - Khara 4K banavnar";
  double progress = 0;
  bool isConverting = false;
  String selRes = "3840x2160";

  List<String> resolutions = [
    "3840x2160",
    "4096x2160",
    "2560x1440",
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
      status = "Khara 4K Conversion chalu ahe...\n2-4 minute lagtil - 100% Real Upscaling";
      progress = 0.05;
    });

    try {
      Directory movies = Directory("/storage/emulated/0/Movies/4KConverterPro");
      if (!await movies.exists()) await movies.create(recursive: true);
      Directory dcim = Directory("/storage/emulated/0/DCIM/4KConverterPro");
      if (!await dcim.exists()) await dcim.create(recursive: true);
      Directory download = Directory("/storage/emulated/0/Download");

      String outName = "REAL_4K_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";
      String outPath = movies.path + "/" + outName;

      String width = selRes.split("x")[0];
      String height = selRes.split("x")[1];

      // 100% REAL 4K Command - Lanczos Filter ne Pixel wadhavto
      String cmd = "-i " + inputFile!.path + " -vf scale=" + width + ":" + height + ":flags=lanczos -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k -y " + outPath;

      FFmpegKit.executeAsync(cmd, (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          try {
            await File(outPath).copy(dcim.path + "/" + outName);
            await File(outPath).copy(download.path + "/" + outName);
          } catch (_) {}
          setState(() {
            status = "SUCCESS! Khara " + selRes + " banla!\n" + outPath + "\nGallery madhe Check kar - Details madhe " + selRes + " disel!";
            progress = 1.0;
            isConverting = false;
          });
        } else {
          final logs = await session.getFailStackTrace();
          setState(() {
            status = "Failed: " + (logs?? "Error");
            isConverting = false;
          });
        }
      }, (log) {}, (Statistics stats) {
        // Progress update
        setState(() {
          int time = stats.getTime();
          // Time varun progress andaj
          if (time > 0) {
            progress = (time / 100000).clamp(0.1, 0.95);
          }
        });
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
      appBar: AppBar(title: const Text("Real 4K Converter Pro"), backgroundColor: const Color(0xFF1A1A1A), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurple, width: 2)),
              child: inputFile == null
                 ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 50, color: Colors.grey), Text("Video Nivda")])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, size: 40, color: Colors.green), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text(inputFile!.path.split('/').last, textAlign: TextAlign.center, style: TextStyle(fontSize: 11)))]),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
              child: DropdownButton<String>(
                value: selRes,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E1E),
                underline: const SizedBox(),
                items: resolutions.map((e) => DropdownMenuItem(value: e, child: Text(e + " (Real Upscale)"))).toList(),
                onChanged: (v) => setState(() => selRes = v!),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.grey[800], color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: pickVideo, icon: const Icon(Icons.folder_open), label: const Text("VIDEO NIVDA"), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 58, child: ElevatedButton.icon(onPressed: isConverting? null : convertReal4K, icon: isConverting? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.hd), label: Text(isConverting? "4K BANAVAT AHE..." : "KHARA 4K MADHE CONVERT KARA"), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple))),
            const SizedBox(height: 15),
            const Text("Ha Lanczos Filter ne pratyek pixel navin banvel - 1080p cha video kharach 3840x2160 hoil. Gallery > Video Details madhe check kar!", style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
