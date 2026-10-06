import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';

void main() => runApp(MaterialApp(home: ConverterApp(), debugShowCheckedModeBanner: false));

class ConverterApp extends StatefulWidget {
  @override State<ConverterApp> createState() => _ConverterAppState();
}

class _ConverterAppState extends State<ConverterApp> {
  bool isConverting = false;
  double progress = 0;
  String status = "Video निवडा आणि 4K मध्ये Convert करा";
  int videoDuration = 0;

  Future<void> pickAndConvert() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;
    String? inputPath = result.files.single.path;
    if (inputPath == null) return;

    // 1. Video चा total duration काढा
    final info = await FFprobeKit.getMediaInformation(inputPath);
    final mediaInfo = info.getMediaInformation();
    videoDuration = (double.tryParse(mediaInfo?.getDuration() ?? "0") ?? 0).toInt() * 1000;

    setState(() { isConverting = true; progress = 0; status = "Real 4K मध्ये Convert होत आहे..."; });

    String outputPath = "/storage/emulated/0/Movies/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String command = "-i \"$inputPath\" -vf scale=3840:2160 -c:v libx264 -pix_fmt yuv420p -preset ultrafast -crf 23 -c:a aac -movflags +faststart \"$outputPath\"";

    // 2. Real time progress साठी Async execute
    await FFmpegKit.executeAsync(command, (session) async {
      final code = await session.getReturnCode();
      setState(() {
        isConverting = false;
        if (ReturnCode.isSuccess(code)) {
          progress = 100;
          status = "Success! Movies folder madhe save jhala";
        } else {
          status = "Failed: $code";
        }
      });
    }, (Statistics stats) {
      if (videoDuration > 0) {
        setState(() {
          progress = (stats.getTime() / videoDuration * 100).clamp(0, 100).toDouble();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isConverting ? Color(0xFF020B1E) : Colors.white,
      appBar: AppBar(title: Text("Real 4K Converter Pro"), backgroundColor: Colors.deepPurple),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (isConverting) ...[
              Container(
                width: 320, height: 32,
                decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent, width: 2), borderRadius: BorderRadius.circular(20), color: Color(0xFF0A1931)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF00FFFF)]),
                          boxShadow: [BoxShadow(color: Colors.cyanAccent, blurRadius: 20)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text("LOADING... ${progress.toInt()}%", style: TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
            SizedBox(height: 30),
            Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isConverting ? Colors.white : Colors.black)),
            SizedBox(height: 40),
            Opacity(opacity: isConverting ? 0.2 : 1, child: ElevatedButton(onPressed: isConverting ? null : pickAndConvert, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)), child: Text("SELECT VIDEO & CONVERT TO 4K"))),
          ]),
        ),
      ),
    );
  }
}
