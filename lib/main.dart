import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(home: ConverterApp(), debugShowCheckedModeBanner: false));

class ConverterApp extends StatefulWidget {
  @override State<ConverterApp> createState() => _ConverterAppState();
}

class _ConverterAppState extends State<ConverterApp> {
  String selectedQuality = "4K";
  Map<String, String> qualityMap = {"4K": "3840:2160", "2K": "2560:1440", "1080p": "1920:1080"};
  bool isConverting = false;
  double progress = 0;
  String status = "Ready";
  List<String> convertedFiles = [];
  VideoPlayerController? controller;
  RangeValues trimRange = const RangeValues(0, 100);
  List<String> inputFiles = [];
  String logText = "";

  Future<void> pickVideos() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
    if (result == null) return;
    inputFiles = result.files.map((f) => f.path!).toList();
    if (inputFiles.isNotEmpty) {
      var c = VideoPlayerController.file(File(inputFiles.first));
      await c.initialize();
      setState(() {
        controller = c;
        status = "${inputFiles.length} Video selected";
      });
    }
  }

  Future<void> convertAll() async {
    if (inputFiles.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    setState(() { isConverting = true; progress = 0; convertedFiles.clear(); logText = ""; });
    
    int done = 0;
    for (String inputPath in inputFiles) {
      String target = qualityMap[selectedQuality]!;
      String outputPath = "${dir.path}/CLEAR_${selectedQuality}_${DateTime.now().millisecondsSinceEpoch}_$done.mp4";

      String clearFilter = "scale=$target:flags=bicubic:force_original_aspect_ratio=increase,crop=$target,setsar=1,unsharp=5:5:0.8:3:3:0.4";

      String command = "-y -i \"$inputPath\" -vf \"$clearFilter\" -c:v libx264 -preset ultrafast -crf 20 -c:a aac \"$outputPath\"";

      setState(() => status = "Converting ${done+1}/${inputFiles.length}...");
      
      var session = await FFmpegKit.execute(command);
      var logs = await session.getAllLogsAsString();
      var code = await session.getReturnCode();
      
      if (code != null && code.isValueSuccess()) {
        convertedFiles.add(outputPath);
        setState(() => logText = "Success");
      } else {
        setState(() { logText = logs ?? "Failed"; status = "Failed - see log"; });
        break;
      }
      done++;
      setState(() => progress = done / inputFiles.length);
    }

    if (convertedFiles.isNotEmpty) {
      var c = VideoPlayerController.file(File(convertedFiles.last));
      await c.initialize();
      await c.play();
      setState(() {
        controller = c;
        isConverting = false;
        status = "Done! Saved";
        progress = 1;
      });
    } else {
      setState(() => isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("4K Clear Pro FIXED"), backgroundColor: Colors.deepPurple),
      body: SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
        Row(children: ["4K","2K","1080p"].map((q) => Expanded(child: Padding(padding: EdgeInsets.all(4), child: ChoiceChip(label: Text(q), selected: selectedQuality==q, onSelected: (v){ if(v) setState(()=> selectedQuality=q); })))).toList()),
        ElevatedButton(onPressed: pickVideos, child: Text("SELECT VIDEOS")),
        Text("Trim: ${trimRange.start.toInt()}% - ${trimRange.end.toInt()}%"),
        RangeSlider(values: trimRange, onChanged: (v)=> setState(()=> trimRange=v), min: 0, max: 100),
        if(controller!=null && controller!.value.isInitialized)
          Container(height: 220, child: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!))),
        if(isConverting) LinearProgressIndicator(value: progress),
        Text(status, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(logText, style: TextStyle(fontSize: 10, color: Colors.red)),
        ElevatedButton(onPressed: isConverting || inputFiles.isEmpty ? null : convertAll, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50)), child: Text("CONVERT NOW")),
        for(var f in convertedFiles) ListTile(title: Text(f.split("/").last, style: TextStyle(fontSize: 11)), trailing: IconButton(icon: Icon(Icons.share), onPressed: () => Share.shareXFiles([XFile(f)]))),
      ])),
    );
  }
}
