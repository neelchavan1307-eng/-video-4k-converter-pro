import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MaterialApp(home: MergedApp(), debugShowCheckedModeBanner: false));
}

class MergedApp extends StatefulWidget {
  @override
  State<MergedApp> createState() => MergedAppState();
}

class MergedAppState extends State<MergedApp> {
  File? pickedFile;
  VideoPlayerController? controller;
  String status = "Ready";
  bool processing = false;
  bool showComparison = true;
  double previewProgress = 0;
  double convertProgress = 0;

  double focusFilter = 65;
  double fourKFilter = 80;
  double whitening = 35;
  double brilliance = 30;
  double sharpen = 75;
  String selectedMode = "Devi Glow";
  double intensity = 40;
  String selectedCategory = "Cinematic";
  String selectedFilter = "Wong Kar Wai";

  final categories = {
    "Cinematic": ["Green Orange", "Sicily", "Badbunny", "Wong Kar Wai", "Hasselblad 2", "Oppenheimer", "Freedom", "Kendall", "Black Panther"],
    "Quality Enhance": ["Quality Boost", "HD Skin", "HD Uplight", "Quality II"],
    "Glow": ["Film CCD", "Glow", "Dreamy Haze"],
    "Vintage": ["Antique", "Retro Film", "Classic"],
    "Night": ["Lunar Night", "Midnight", "Urban Night"],
  };

  Future<void> pick() async {
    await Permission.storage.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r!= null) {
      pickedFile = File(r.files.single.path!);
      controller?.dispose();
      controller = VideoPlayerController.file(pickedFile!);
      await controller!.initialize();
      controller!.setLooping(true);
      controller!.play();
      Timer.periodic(Duration(milliseconds: 200), (t) {
        if (controller!= null && controller!.value.isInitialized) {
          var dur = controller!.value.duration.inMilliseconds;
          if (dur == 0) dur = 1;
          setState(() {
            previewProgress = controller!.value.position.inMilliseconds / dur;
          });
        }
      });
      setState(() {
        status = "Ready";
      });
    }
  }

  // Preview sathi matrix
  List<double> getMatrix() {
    double w = whitening;
    double ii = intensity / 50;
    List<double> m;
    if (selectedMode == "Devi Glow") {
      m = [1.4, 0, 0, 0, 15 + w, 0, 1.2, 0, 0, 10 + w, 0, 0, 0.9, 0, -5 + w, 0, 0, 0, 1, 0];
    } else if (selectedMode == "Cute Soft") {
      m = [1.3, 0.1, 0.1, 0, 25 + w, 0.1, 1.2, 0.1, 0, 20 + w, 0.1, 0.1, 1.4, 0, 30 + w, 0, 0, 0, 1, 0];
    } else {
      m = [1.6, -0.1, 0, 0, 5 + w / 2, -0.1, 1.1, 0, 0, 5 + w / 2, 0, 0, 1.8, 0, 5 + w / 2, 0, 0, 0, 1, 0];
    }
    // Filter cha effect preview var pan
    if (selectedFilter == "Oppenheimer") m[0] = m[0] + 0.15 * ii;
    if (selectedFilter == "Wong Kar Wai") {
      m[0] = m[0] + 0.2 * ii;
      m[6] = m[6] - 0.1 * ii;
    }
    if (selectedFilter == "Glow") {
      m[4] = m[4] + 20 * ii;
      m[9] = m[9] + 15 * ii;
    }
    return m;
  }

  // SAVE sathi - techch matrix FFmpeg madhe convert - hech main fix aahe
  String getFFmpegFilter() {
    List<double> mat = getMatrix();
    double sharpVal = (sharpen + focusFilter) / 100 * 2.0;
    double sat = 1.0 + fourKFilter / 70;
    double bright = whitening / 500;
    double contrast = 1.0 + brilliance / 70;

    bool isPortrait = true;
    if (controller!= null) {
      isPortrait = controller!.value.size.height > controller!.value.size.width;
    }

    String scalePart = "";
    if (isPortrait) {
      scalePart = "scale=1080:1920:force_original_aspect_ratio=decrease:flags=lanczos+accurate_rnd,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black,scale=2160:3840:flags=lanczos:threads=4";
    } else {
      scalePart = "scale=1920:1080:force_original_aspect_ratio=decrease:flags=lanczos+accurate_rnd,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=black,scale=3840:2160:flags=lanczos:threads=4";
    }

    // ColorFilter matrix la FFmpeg colorchannelmixer madhe convert
    // mat[0]=rr, mat[1]=rg, mat[2]=rb, mat[5]=gr, mat[6]=gg etc
    String cc = "colorchannelmixer=rr=" + mat[0].toString() + ":rg=" + mat[1].toString() + ":rb=" + mat[2].toString() + ":gr=" + mat[5].toString() + ":gg=" + mat[6].toString() + ":gb=" + mat[7].toString() + ":br=" + mat[10].toString() + ":bg=" + mat[11].toString() + ":bb=" + mat[12].toString();

    String eq = "eq=brightness=" + (bright + mat[4] / 600).toString() + ":contrast=" + contrast.toString() + ":saturation=" + sat.toString();

    String sharp = "unsharp=5:5:" + sharpVal.toString() + ":5:5:0";

    String filterExtra = "";
    if (selectedFilter == "Oppenheimer") filterExtra = ",curves=strong_contrast,eq=saturation=0.85";
    if (selectedFilter == "Wong Kar Wai") filterExtra = ",curves=vintage,colorbalance=rs=0.2:gs=-0.1:bs=-0.2";
    if (selectedFilter == "Green Orange") filterExtra = ",colorbalance=rs=0.3:gs=-0.1:bs=-0.3";
    if (selectedFilter == "Lunar Night") filterExtra = ",eq=contrast=1.25:brightness=-0.06:saturation=0.7";
    if (selectedFilter == "Glow") filterExtra = ",gblur=sigma=0.5:steps=1," + eq + ",eq=contrast=1.1";

    String finalFilter = scalePart + "," + sharp + "," + cc + "," + eq + filterExtra + ",unsharp=5:5:0.9:5:5:0";
    return finalFilter;
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() {
      processing = true;
      convertProgress = 0.01;
    });

    FFmpegKitConfig.enableStatisticsCallback((s) {
      double p = 0;
      if (controller!= null) {
        var dur = controller!.value.duration.inMilliseconds;
        if (dur == 0) dur = 1;
        p = s.getTime() / dur;
      }
      if (p > 0.99) p = 0.99;
      if (p < 0) p = 0;
      setState(() {
        convertProgress = p;
        status = (p * 100).toInt().toString() + "% " + selectedFilter + " CLEAR";
      });
    });

    Directory d = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if (!await d.exists()) await d.create(recursive: true);
    String out = d.path + "/CLEAR_" + selectedFilter.replaceAll(" ", "_") + "_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";

    String vf = getFFmpegFilter();
    String cmd = "-y -i '" + pickedFile!.path + "' -vf \"" + vf + "\" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a copy '" + out + "'";

    var session = await FFmpegKit.execute(cmd);
    FFmpegKitConfig.enableStatisticsCallback(null);
    var rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      setState(() {
        processing = false;
        convertProgress = 1.0;
        status = "DONE! CLEAR Saved " + out;
      });
    } else {
      setState(() {
        processing = false;
        status = "Failed";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(title: Text("HATKE CLEAR FIX", style: TextStyle(fontSize: 13)), backgroundColor: Colors.purple, toolbarHeight: 38),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(6),
        child: Column(
          children: [
            SizedBox(height: 38, child: ElevatedButton(onPressed: processing? null : pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 38)), child: Text("SELECT VIDEO", style: TextStyle(fontSize: 12)))),
            if (controller!= null && controller!.value.isInitialized)
              Column(
                children: [
                  SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: controller!.value.aspectRatio,
                      child: Stack(
                        children: [
                          VideoPlayer(controller!),
                          if (true)
                            Positioned.fill(
                              child: ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: Container(color: Colors.transparent)),
                            ),
                          // REAL / FILTERED label - screenshot sarkha
                          Positioned(left: 4, bottom: 4, child: Container(padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2), color: Colors.black54, child: Text("REAL", style: TextStyle(color: Colors.white, fontSize: 7)))),
                          Positioned(right: 4, bottom: 4, child: Container(padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2), color: Colors.pink, child: Text(selectedFilter.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 6)))),
                          Positioned(left: controller!.value.size.width / 2 - 1, top: 0, bottom: 0, child: Container(width: 1.5, color: Colors.yellow)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(height: 10, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(widthFactor: (processing? convertProgress : previewProgress).clamp(0.0, 1.0), alignment: Alignment.centerLeft, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple, Colors.pink, Colors.orange, Colors.yellow]))))),
                ],
              ),
            SizedBox(height: 8),
            Text("Adjust Bar - Chota Kela", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8)),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(children: [SizedBox(width: 60, child: Text("Focus", style: TextStyle(color: Colors.white70, fontSize: 8))), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 1.2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3.5)), child: Slider(value: focusFilter, min: 0, max: 100, activeColor: Colors.pinkAccent, inactiveColor: Colors.white24, onChanged: (v) => setState(() => focusFilter = v))))]),
                  Row(children: [SizedBox(width: 60, child: Text("4K", style: TextStyle(color: Colors.white70, fontSize: 8))), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 1.2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3.5)), child: Slider(value: fourKFilter, min: 0, max: 100, activeColor: Colors.pinkAccent, inactiveColor: Colors.white24, onChanged: (v) => setState(() => fourKFilter = v))))]),
                  Row(children: [SizedBox(width: 60, child: Text("Sharp", style: TextStyle(color: Colors.white70, fontSize: 8))), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 1.2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3.5)), child: Slider(value: sharpen, min: 0, max: 100, activeColor: Colors.pinkAccent, inactiveColor: Colors.white24, onChanged: (v) => setState(() => sharpen = v))))]),
                ],
              ),
            ),
            SizedBox(height: 6),
            Wrap(spacing: 4, children: categories.keys.map((cat) { bool sel = cat == selectedCategory; return ChoiceChip(label: Text(cat, style: TextStyle(fontSize: 9)), selected: sel, selectedColor: Colors.yellow, onSelected: (b) => setState(() => selectedCategory = cat)); }).toList()),
            SizedBox(height: 4),
            Wrap(spacing: 4, runSpacing: 4, children: (categories[selectedCategory] as List).map((f) { bool sel = f == selectedFilter; return GestureDetector(onTap: () => setState(() => selectedFilter = f), child: Container(width: (MediaQuery.of(context).size.width - 30) / 3, padding: EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: sel? Colors.white : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(5), border: sel? Border.all(color: Colors.yellow) : null), child: Text(f, textAlign: TextAlign.center, style: TextStyle(color: sel? Colors.black : Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)))); }).toList()),
            SizedBox(height: 8),
            Text(status, style: TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center),
            SizedBox(height: 8),
            SizedBox(height: 44, child: ElevatedButton(onPressed: processing? null : convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 44)), child: Text(processing? "RENDERING..." : "EXPORT " + selectedFilter.toUpperCase() + " CLEAR 4K @ " + intensity.toInt().toString() + "%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
