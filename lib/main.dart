import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MaterialApp(home: ProApp(), debugShowCheckedModeBanner: false));

class ProApp extends StatefulWidget {
  @override
  State<ProApp> createState() => _ProAppState();
}

class _ProAppState extends State<ProApp> {
  String status = "Ready";
  String quality = "4K";
  File? pickedFile;
  double trimStart = 0;
  double trimEnd = 100;

  Future<void> pickVideo() async {
    await Permission.storage.request();
    var result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        pickedFile = File(result.files.single.path!);
        status = "Selected: ${result.files.single.name}";
      });
    }
  }

  Future<void> convert() async {
    if (pickedFile == null) {
      setState(() => status = "First SELECT VIDEOS");
      return;
    }
    setState(() => status = "Converting to $quality... Wait");

    Directory dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    String outPath = "${dir.path}/clear_${quality}_${DateTime.now().millisecondsSinceEpoch}.mp4";

    // FIXED: Real Clear Filter - scale + unsharp + denoise
    String scale = quality == "4K" ? "3840:2160" : quality == "2K" ? "2560:1440" : "1920:1080";
    String cmd = "-y -i '${pickedFile!.path}' -vf scale=$scale:flags=lanczos,unsharp=5:5:1.0:5:5:0.0,hqdn3d=1.5:1.5:6:6 -c:v libx264 -preset ultrafast -crf 23 -c:a aac '$outPath'";

    await FFmpegKit.execute(cmd).then((session) async {
      final returnCode = await session.getReturnCode();
      if (returnCode != null && returnCode.isValueSuccess()) {
        setState(() => status = "SUCCESS! Saved to: $outPath");
      } else {
        final log = await session.getAllLogsAsString();
        setState(() => status = "FAILED: $log");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("4K Clear Pro FIXED"), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ChoiceChip(label: Text("4K"), selected: quality=="4K", onSelected: (_)=>setState(()=>quality="4K")),
              ChoiceChip(label: Text("2K"), selected: quality=="2K", onSelected: (_)=>setState(()=>quality="2K")),
              ChoiceChip(label: Text("1080p"), selected: quality=="1080p", onSelected: (_)=>setState(()=>quality="1080p")),
            ]),
            SizedBox(height: 15),
            ElevatedButton(onPressed: pickVideo, child: Text("SELECT VIDEOS")),
            Text("Trim: ${trimStart.toInt()}% - ${trimEnd.toInt()}%"),
            RangeSlider(values: RangeValues(trimStart, trimEnd), min: 0, max: 100, onChanged: (v)=>setState((){
              trimStart=v.start; trimEnd=v.end;
            })),
            SizedBox(height: 20),
            Text(status, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: convert,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              child: Text("CONVERT NOW"),
            )
          ],
        ),
      ),
    );
  }
}
