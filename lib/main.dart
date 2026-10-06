import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() => runApp(MaterialApp(home: ConverterApp(), debugShowCheckedModeBanner: false));

class ConverterApp extends StatefulWidget {
  @override State<ConverterApp> createState() => _ConverterAppState();
}

class _ConverterAppState extends State<ConverterApp> with TickerProviderStateMixin {
  bool isConverting = false;
  String status = "Video निवडा आणि 4K मध्ये Convert करा";
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 1500))..repeat();
  }

  Future<void> pickAndConvert() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;
    String? inputPath = result.files.single.path;
    if (inputPath == null) return;
    setState(() { isConverting = true; status = "Real 4K मध्ये Convert होत आहे..."; });
    String outputPath = "/storage/emulated/0/Movies/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String command = "-i \"$inputPath\" -vf scale=3840:2160 -c:v libx264 -pix_fmt yuv420p -preset ultrafast -crf 23 -c:a aac -movflags +faststart \"$outputPath\"";
    await FFmpegKit.execute(command).then((session) async {
      final code = await session.getReturnCode();
      setState(() {
        isConverting = false;
        status = ReturnCode.isSuccess(code) ? "Success! Movies folder madhe save jhala" : "Failed: $code";
      });
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
            if (isConverting)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Column(children: [
                  Container(
                    width: 300, height: 30,
                    decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent, width: 2), borderRadius: BorderRadius.circular(20), color: Color(0xFF0A1931)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _controller.value,
                          child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.cyanAccent]), boxShadow: [BoxShadow(color: Colors.cyanAccent, blurRadius: 15)])),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("LOADING... ${(_controller.value * 100).toInt()}%", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2)),
                ]),
              ),
            SizedBox(height: 30),
            Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isConverting ? Colors.white : Colors.black)),
            SizedBox(height: 40),
            ElevatedButton(onPressed: isConverting ? null : pickAndConvert, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white), child: Text("SELECT VIDEO & CONVERT TO 4K")),
          ]),
        ),
      ),
    );
  }
}
