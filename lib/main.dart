import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart';

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

    final info = await FFprobeKit.getMediaInformation(inputPath);
    final mediaInfo = info.getMediaInformation();
    videoDuration = (double.tryParse(mediaInfo?.getDuration() ?? "0") ?? 0).toInt() * 1000;

    int width = 720; int height = 1280;
    try {
      width = mediaInfo?.getStreams().first.getWidth() ?? 720;
      height = mediaInfo?.getStreams().first.getHeight() ?? 1280;
    } catch(e){}

    bool isPortrait = height > width;
    // Real Video हा Portrait आहे म्हणून 2160x3840
    String target = isPortrait ? "2160:3840" : "3840:2160";

    setState(() { isConverting = true; progress = 0; status = "Real सारखा Full 4K होत आहे..."; });

    await Directory("/storage/emulated/0/Movies").create(recursive: true);
    String outputPath = "/storage/emulated/0/Movies/REAL_4K_${DateTime.now().millisecondsSinceEpoch}.mp4";

    // दाबणार नाही, Real shape राहील
    String command = "-noautorotate -i \"$inputPath\" -vf \"scale=$target:force_original_aspect_ratio=increase,crop=$target:(iw-ow)/2:(ih-oh)/2,setsar=1\" -c:v libx264 -profile:v high -pix_fmt yuv420p -preset ultrafast -crf 20 -c:a copy -movflags +faststart \"$outputPath\"";

    await FFmpegKit.executeAsync(command, (session) async {
      final code = await session.getReturnCode();
      setState(() {
        isConverting = false;
        status = ReturnCode.isSuccess(code) ? "Success! Real सारखा Full Screen 4K" : "Failed";
        progress = ReturnCode.isSuccess(code) ? 100 : 0;
      });
    }, (Log l){}, (Statistics s){
      if(videoDuration>0) setState(()=> progress = (s.getTime()/videoDuration*100).clamp(0,100).toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isConverting ? Color(0xFF020B1E) : Colors.white,
      appBar: AppBar(title: Text("Real 4K Converter"), backgroundColor: Colors.deepPurple),
      body: Center(child: Padding(padding: EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if(isConverting)...[
          Container(width: 320, height: 32, decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent, width: 2), borderRadius: BorderRadius.circular(20), color: Color(0xFF0A1931)), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: progress/100, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF00FFFF)]))))))),
          SizedBox(height: 12),
          Text("LOADING... ${progress.toInt()}%", style: TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
        SizedBox(height: 30),
        Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 40),
        ElevatedButton(onPressed: isConverting ? null : pickAndConvert, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white), child: Text("SELECT VIDEO & CONVERT TO 4K")),
      ]))),
    );
  }
}
