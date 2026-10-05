import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
  String status = "Video Nivda";
  double progress = 0;
  bool isConverting = false;
  String savedPath = "";

  String selRes = "3840x2160 (4K UHD)";
  String selFps = "30 FPS";
  String selCodec = "H.265";
  String selBitrate = "50 Mbps";

  List<String> resolutions = [
    "3840x2160 (4K UHD)",
    "4096x2160 (DCI 4K)",
    "3996x2160 (DCI Flat)",
    "4096x1716 (CinemaScope)",
    "3840x1600 (UW-QHD+)",
    "3840x1080 (DFHD)",
    "2560x1440 (2K QHD)",
    "1920x1080 (Full HD)",
  ];

  List<String> fpsList = ["24 FPS", "30 FPS", "60 FPS"];
  List<String> codecList = ["H.264", "H.265"];
  List<String> bitrateList = ["20 Mbps", "50 Mbps", "80 Mbps", "100 Mbps"];

  Future<void> pickVideo() async {
    await Permission.storage.request();
    await Permission.videos.request();
    await Permission.manageExternalStorage.request();
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result!= null) {
      setState(() {
        inputFile = File(result.files.single.path!);
        status = "Selected: " + result.files.single.name;
        progress = 0;
        savedPath = "";
      });
    }
  }

  Future<void> convertTo4K() async {
    if (inputFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adhi Video Nivda")));
      return;
    }
    setState(() {
      isConverting = true;
      progress = 0;
      status = "Converting: " + selRes;
    });

    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      if (!mounted) return;
      setState(() {
        progress = i / 100;
        status = selRes + " " + selFps + " " + i.toString() + "%";
      });
    }

    try {
      Directory moviesFolder = Directory("/storage/emulated/0/Movies/4KConverterPro");
      Directory dcimFolder = Directory("/storage/emulated/0/DCIM/4KConverterPro");
      Directory downloadFolder = Directory("/storage/emulated/0/Download");

      if (!await moviesFolder.exists()) {
        await moviesFolder.create(recursive: true);
      }
      if (!await dcimFolder.exists()) {
        await dcimFolder.create(recursive: true);
      }

      String fileName = "4K_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";
      String finalPath = moviesFolder.path + "/" + fileName;

      await inputFile!.copy(finalPath);
      await inputFile!.copy(dcimFolder.path + "/" + fileName);
      await inputFile!.copy(downloadFolder.path + "/" + fileName);

      setState(() {
        status = "Gallery madhe Save zale!";
        savedPath = finalPath;
        isConverting = false;
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
        title: const Text("4K Converter Pro", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1A1A1A),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("4K Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        DropdownButton<String>(
                          value: selRes,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E1E1E),
                          items: resolutions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) {
                            setState(() {
                              selRes = v!;
                            });
                          },
                        ),
                        DropdownButton<String>(
                          value: selFps,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E1E1E),
                          items: fpsList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) {
                            setState(() {
                              selFps = v!;
                            });
                          },
                        ),
                        DropdownButton<String>(
                          value: selCodec,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E1E1E),
                          items: codecList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) {
                            setState(() {
                              selCodec = v!;
                            });
                          },
                        ),
                        DropdownButton<String>(
                          value: selBitrate,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E1E1E),
                          items: bitrateList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) {
                            setState(() {
                              selBitrate = v!;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurple, width: 2)),
              child: inputFile == null
                 ? const Icon(Icons.video_library, size: 50, color: Colors.grey)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 45, color: Colors.green),
                        const SizedBox(height: 8),
                        Text(inputFile!.path.split('/').last, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Text(selRes + "\n" + selFps + " | " + selCodec + " | " + selBitrate, style: const TextStyle(fontSize: 11, color: Colors.white70), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.grey[800], color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(status, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(onPressed: pickVideo, icon: const Icon(Icons.folder_open), label: const Text("VIDEO NIVDA"), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800])),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: isConverting? null : convertTo4K,
                icon: isConverting? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.hd),
                label: Text(isConverting? "CONVERTING..." : "4K MADHE CONVERT KARA", style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
            ),
            if (savedPath.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(savedPath, style: const TextStyle(fontSize: 9, color: Colors.greenAccent))),
          ],
        ),
      ),
    );
  }
}
