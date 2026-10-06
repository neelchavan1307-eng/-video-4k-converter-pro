import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(home: Home(), debugShowCheckedModeBanner: false));

class Home extends StatefulWidget { @override _HomeState createState() => _HomeState(); }

class _HomeState extends State<Home> {
  String status = "Video निवडा आणि Real 4K मध्ये Convert करा";
  double progress = 0;
  bool isConverting = false;

  Future<void> pickAndConvert() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;

    setState(() { isConverting = true; status = "Real 4K मध्ये Convert होत आहे..."; progress = 0.1; });

    File file = File(result.files.single.path!);
    Directory dir = await getApplicationDocumentsDirectory();
    String outPath = "${dir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";

    // REAL 4K COMMAND - 3840x2160 lanczos
    String cmd = "-i \"${file.path}\" -vf scale=3840:2160:flags=lanczos -c:v libx264 -preset ultrafast -crf 18 -c:a aac \"$outPath\"";

    await FFmpegKit.execute(cmd).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() { status = "Success! Real 4K Video तयार: $outPath"; progress = 1.0; isConverting = false; });
      } else {
        setState(() { status = "Failed!"; isConverting = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Real 4K Converter Pro"), backgroundColor: Colors.deepPurple),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        SizedBox(height: 20),
        if(isConverting) CircularProgressIndicator(value: progress),
        SizedBox(height: 20),
        ElevatedButton(onPressed: isConverting? null : pickAndConvert, child: Text("SELECT VIDEO & CONVERT TO 4K")),
      ])),
    );
  }
}
