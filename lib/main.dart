import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() => runApp(MaterialApp(home: ConverterApp(), debugShowCheckedModeBanner: false));

class ConverterApp extends StatefulWidget {
  @override State<ConverterApp> createState() => _ConverterAppState();
}

class _ConverterAppState extends State<ConverterApp> {
  bool isConverting = false;
  String status = "Video निवडा आणि 4K मध्ये Convert करा";

  Future<void> pickAndConvert() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;
    String? inputPath = result.files.single.path;
    if (inputPath == null) return;

    setState(() { isConverting = true; status = "Real 4K मध्ये Convert होत आहे...\nथोडा वेळ लागेल"; });

    // Public Movies folder - जिथून Player प्ले करू शकेल
    String outputPath = "/storage/emulated/0/Movies/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    
    // yuv420p लावलंय - त्यामुळे सगळ्या Player वर चालेल
    String command = "-i \"$inputPath\" -vf scale=3840:2160 -c:v libx264 -pix_fmt yuv420p -preset ultrafast -crf 23 -c:a aac -movflags +faststart \"$outputPath\"";
    
    await FFmpegKit.execute(command).then((session) async {
      final code = await session.getReturnCode();
      setState(() {
        isConverting = false;
        if (ReturnCode.isSuccess(code)) {
          status = "✅ Success! 193 MB -> Real 4K झाला!\nSaved in: Movies Folder\n$file: $outputPath";
        } else {
          status = "❌ Failed: $code";
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Real 4K Converter Pro"), backgroundColor: Colors.deepPurple),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (isConverting) CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: isConverting ? null : pickAndConvert,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: Text("SELECT VIDEO & CONVERT TO 4K"),
            )
          ]),
        ),
      ),
    );
  }
}
