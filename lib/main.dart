import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(MaterialApp(home: ConverterApp(), debugShowCheckedModeBanner: false));

class ConverterApp extends StatefulWidget {
  @override
  State<ConverterApp> createState() => _ConverterAppState();
}

class _ConverterAppState extends State<ConverterApp> {
  String selectedQuality = "4K";
  Map<String, String> qualityMap = {"4K": "3840:2160", "2K": "2560:1440", "1080p": "1920:1080"};
  bool isConverting = false;
  double progress = 0;
  String status = "Ready to Clear Convert";
  List<String> convertedFiles = [];
  VideoPlayerController? controller;
  RangeValues trimRange = const RangeValues(0, 100);
  int totalDurationMs = 0;
  List<String> inputFiles = [];

  Future<void> pickVideos() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
    if (result == null) return;
    inputFiles = result.files.map((f) => f.path!).toList();
    if (inputFiles.isNotEmpty) {
      final info = await FFprobeKit.getMediaInformation(inputFiles.first);
      totalDurationMs = (double.tryParse(info.getMediaInformation()?.getDuration() ?? "0") ?? 0).toInt() * 1000;
      var c = VideoPlayerController.file(File(inputFiles.first));
      await c.initialize();
      setState(() {
        controller = c;
        status = "${inputFiles.length} Video selected";
      });
    }
  }

  String getTargetRes(int w, int h) {
    String base = qualityMap[selectedQuality]!;
    bool isPortrait = h > w;
    if (isPortrait) {
      var parts = base.split(":");
      return parts[1] + ":" + parts[0];
    }
    return base;
  }

  Future<void> convertAll() async {
    if (inputFiles.isEmpty) return;
    setState(() { isConverting = true; progress = 0; convertedFiles.clear(); });
    int done = 0;

    for (String inputPath in inputFiles) {
      final info = await FFprobeKit.getMediaInformation(inputPath);
      var mediaInfo = info.getMediaInformation();
      int w = mediaInfo?.getStreams().first.getWidth() ?? 1920;
      int h = mediaInfo?.getStreams().first.getHeight() ?? 1080;
      int fileDuration = (double.tryParse(mediaInfo?.getDuration() ?? "0") ?? 0).toInt() * 1000;

      double startSec = (trimRange.start / 100) * fileDuration / 1000;
      double endSec = (trimRange.end / 100) * fileDuration / 1000;

      String target = getTargetRes(w, h);
      String outputPath = "/storage/emulated/0/Movies/CLEAR_${selectedQuality}_${DateTime.now().millisecondsSinceEpoch}_$done.mp4";
      await Directory("/storage/emulated/0/Movies").create(recursive: true);

      String trimCmd = "";
      if (trimRange.start > 0 || trimRange.end < 100) {
        trimCmd = "-ss $startSec -to $endSec";
      }

      // CLEAR FILTER - FIXED
      String clearFilter = "scale=" + target + ":flags=lanczos:force_original_aspect_ratio=increase,crop=" + target + ",setsar=1,unsharp=5:5:1.2:5:5:0.0,hqdn3d=1.5:1.5:6:6,eq=contrast=1.1:brightness=0.02:saturation=1.15";

      String command = "-y $trimCmd -i \"$inputPath\" -vf \"$clearFilter\" -c:v libx264 -profile:v high -pix_fmt yuv420p -preset ultrafast -crf 18 -c:a aac -b:a 192k -movflags +faststart \"$outputPath\"";

      await FFmpegKit.execute(command);
      convertedFiles.add(outputPath);
      done++;
      setState(() { progress = (done / inputFiles.length * 100); });
    }

    var c = VideoPlayerController.file(File(convertedFiles.last));
    await c.initialize();
    await c.play();
    setState(() {
      controller = c;
      isConverting = false;
      status = "Success! Clear $selectedQuality done";
      progress = 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("4K Clear Pro"), backgroundColor: Colors.deepPurple),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: ["4K","2K","1080p"].map((q) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: ChoiceChip(label: Text(q), selected: selectedQuality==q, onSelected: (v){ if(v) setState(()=> selectedQuality=q); })
                  )
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: pickVideos, child: Text("SELECT VIDEOS (Batch)")),
            SizedBox(height: 10),
            Text("Trim: ${trimRange.start.toInt()}% - ${trimRange.end.toInt()}%"),
            RangeSlider(values: trimRange, onChanged: (v)=> setState(()=> trimRange=v), min: 0, max: 100, divisions: 100),
            if(controller!=null && controller!.value.isInitialized)
              Container(height: 220, child: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!))),
            SizedBox(height: 15),
            if(isConverting) LinearProgressIndicator(value: progress/100),
            Text(status, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: isConverting || inputFiles.isEmpty ? null : convertAll,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50)),
              child: Text("CONVERT TO CLEAR $selectedQuality")
            ),
            SizedBox(height: 20),
            for(var f in convertedFiles) ListTile(
              title: Text(f.split("/").last, style: TextStyle(fontSize: 12)),
              trailing: IconButton(icon: Icon(Icons.share), onPressed: () => Share.shareXFiles([XFile(f)])),
            )
          ]
        )
      )
    );
  }
}
