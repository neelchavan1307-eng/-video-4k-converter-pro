import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MasterEditor(), theme: ThemeData.dark()));
}

class MasterEditor extends StatefulWidget {
  @override
  _MasterEditorState createState() => _MasterEditorState();
}

class _MasterEditorState extends State<MasterEditor> {
  String? videoPath;
  VideoPlayerController? vc;
  bool processing = false;
  bool blurBg = false;
  bool stabilize = false;
  double progress = 0;
  List<String> selected = [];
  String status = "Video निवडा";
  String aiReason = "AI: Video टाकल्यावर Analysis करेल";
  List<String> aiList = [];

  Map<String, Map<String, String>> filters = {
    "f01": {"name": "Normal", "cmd": "", "c": "normal"},
    "f02": {"name": "B&W", "cmd": "hue=s=0", "c": "bw"},
    "f03": {"name": "Sepia", "cmd": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", "c": "sepia"},
    "f05": {"name": "Warm Birthday", "cmd": "eq=brightness=0.06:saturation=1.35", "c": "warm"},
    "f07": {"name": "Bright", "cmd": "eq=brightness=0.25:contrast=1.25", "c": "bright"},
    "f08": {"name": "Vivid", "cmd": "eq=saturation=2.2:contrast=1.3", "c": "vivid"},
    "f10": {"name": "Cinematic", "cmd": "eq=contrast=1.2:saturation=1.25", "c": "cinematic"},
    "f12": {"name": "HDR 4K", "cmd": "eq=contrast=1.5:saturation=1.45", "c": "vivid"},
    "f15": {"name": "Dreamy Glow", "cmd": "eq=brightness=0.15:saturation=1.3", "c": "bright"},
    "f25": {"name": "4K Ultra", "cmd": "scale=3840:2160:flags=lanczos", "c": "normal"},
    "f26": {"name": "Sharpen", "cmd": "unsharp=5:5:1", "c": "normal"},
    "f28": {"name": "Night Boost", "cmd": "eq=brightness=0.35:contrast=1.25", "c": "bright"},
    "f30": {"name": "Landscape", "cmd": "eq=saturation=1.6:contrast=1.2", "c": "vivid"},
    "f73": {"name": "Love Glow", "cmd": "eq=brightness=0.15:saturation=1.6", "c": "warm"},
    "f74": {"name": "Rose Pink", "cmd": "colorbalance=rs=0.4:bs=0.2", "c": "warm"},
    "f75": {"name": "Heart Bokeh", "cmd": "eq=brightness=0.2:saturation=1.4", "c": "bright"},
    "f76": {"name": "Prem Special", "cmd": "eq=saturation=1.6", "c": "vivid"},
    "f77": {"name": "Road Love", "cmd": "eq=contrast=1.3:saturation=1.5", "c": "cinematic"},
    "f78": {"name": "AI UHD Pro", "cmd": "scale=3840:2160:flags=lanczos,eq=contrast=1.2", "c": "vivid"},
  };

  List<String> get keys {
    while (filters.length < 72) {
      int i = filters.length + 1;
      filters["fx$i"] = {"name": "Pro $i", "cmd": "eq=saturation=1.3", "c": "normal"};
    }
    return filters.keys.toList();
  }

  ColorFilter getPreview() {
    if (selected.isEmpty) {
      return ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
    String c = filters[selected.last]!["c"]!;
    if (c == "bw") {
      return ColorFilter.matrix([0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]);
    }
    if (c == "warm") {
      return ColorFilter.mode(Colors.orange.withOpacity(0.25), BlendMode.overlay);
    }
    if (c == "vivid") {
      return ColorFilter.matrix([1.35, 0, 0, 0, 0, 0, 1.35, 0, 0, 0, 0, 0, 1.35, 0, 0, 0, 0, 0, 1, 0]);
    }
    return ColorFilter.mode(Colors.white.withOpacity(0.2), BlendMode.lighten);
  }

  Future<void> analyzeAI(String path) async {
    var infoS = await FFprobeKit.getMediaInformation(path);
    var info = infoS.getMediaInformation();
    double dur = double.tryParse(info?.getDuration()?? "0")?? 0;
    int w = info?.getStreams().first.getWidth()?? 0;
    String name = path.toLowerCase();
    if (name.contains("birthday") || dur < 15) {
      aiList = ["f05", "f15", "f78"];
      aiReason = "AI: Birthday ${dur.toInt()}s ${w}p - Warm + Dreamy + AI UHD Best Combo!";
      selected = ["f05", "f15"];
    } else if (w < 1280) {
      aiList = ["f78", "f26", "f12"];
      aiReason = "AI: Low Quality ${w}p - 4K Ultra + Sharpen + HDR - Proper 4K Convert!";
      selected = ["f78", "f26"];
    } else {
      aiList = ["f10", "f08", "f78"];
      aiReason = "AI: Daylight ${w}p - Cinematic + Vivid + AI UHD Best!";
      selected = ["f10"];
    }
    setState(() {});
  }

  Future pickVideo() async {
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r == null) return;
    videoPath = r.files.single.path!;
    vc?.dispose();
    vc = VideoPlayerController.file(File(videoPath!));
    await vc!.initialize();
    vc!.setLooping(true);
    vc!.play();
    await analyzeAI(videoPath!);
    setState(() {
      status = "Ready: ${r.files.single.name}";
    });
  }

  void toggle(String k) {
    setState(() {
      if (selected.contains(k)) {
        selected.remove(k);
      } else if (selected.length < 10) {
        selected.add(k);
      }
    });
  }

  void openFullScreen() {
    if (vc == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Center(
            child: AspectRatio(
              aspectRatio: vc!.value.aspectRatio,
              child: ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!)),
            ),
          ),
          Positioned(
            top: 40,
            left: 15,
            child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("BACK TO EDITING"),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF7C4DFF), minimumSize: Size(double.infinity, 50)),
            ),
          ),
        ]),
      );
    }));
  }

  Future export() async {
    if (videoPath == null) return;
    setState(() {
      processing = true;
      progress = 0;
    });
    var tmp = await getTemporaryDirectory();
    var out = "${tmp.path}/MASTER_${DateTime.now().millisecondsSinceEpoch}.mp4";
    List<String> vf = ["scale=3840:2160:flags=lanczos"];
    if (blurBg) vf.add("gblur=sigma=2");
    if (stabilize) vf.add("deshake");
    for (var k in selected) {
      if (filters[k]!["cmd"]!.isNotEmpty) vf.add(filters[k]!["cmd"]!);
    }
    String cmd = "-i $videoPath -vf ${vf.join(",")} -c:v libx264 -preset ultrafast -crf 18 -c:a aac $out";
    FFmpegKit.executeAsync(cmd, (s) async {
      if (ReturnCode.isSuccess(await s.getReturnCode())) {
        var dir = Directory("/storage/emulated/0/Movies/4K Converter");
        if (!await dir.exists()) await dir.create(recursive: true);
        await File(out).copy("${dir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4");
        setState(() {
          processing = false;
          progress = 100;
          status = "Saved to Gallery!";
        });
      } else {
        setState(() {
          processing = false;
          status = "Failed";
        });
      }
    }, (l) {}, (st) {
      setState(() {
        progress = (st.getTime() / 1000).clamp(0, 100).toDouble();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("MASTER 4K - ${selected.length} Filters", style: TextStyle(fontSize: 13)),
        actions: [
          ElevatedButton(onPressed: export, child: Text("Export 4K"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF5AC8FA), foregroundColor: Colors.black)),
          SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: Stack(children: [
              Center(
                child: vc!= null && vc!.value.isInitialized
                   ? AspectRatio(aspectRatio: vc!.value.aspectRatio, child: ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!)))
                    : GestureDetector(onTap: pickVideo, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 50, color: Colors.white24), ElevatedButton(onPressed: pickVideo, child: Text("PICK VIDEO"))])),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: GestureDetector(
                  onTap: openFullScreen,
                  child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white, width: 1.5)), child: Icon(Icons.fullscreen, size: 18, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
        Container(
          height: 135,
          color: Color(0xFF151515),
          padding: EdgeInsets.all(6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("FILTERS - 72 Right to Left Swipe - ${selected.length}/10 Selected", style: TextStyle(fontSize: 8, color: Colors.orange)),
            SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Wrap(
                  direction: Axis.vertical,
                  spacing: 6,
                  runSpacing: 6,
                  children: keys.map((k) {
                    bool sel = selected.contains(k);
                    return GestureDetector(
                      onTap: () => toggle(k),
                      child: Container(
                        width: 64,
                        height: 36,
                        decoration: BoxDecoration(color: sel? Colors.orange : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(6), border: Border.all(color: sel? Colors.white : Colors.transparent, width: sel? 1.5 : 0)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(sel? Icons.check_circle : Icons.filter_alt, size: 11, color: sel? Colors.black : Colors.white60),
                          Text(filters[k]!["name"]!, style: TextStyle(fontSize: 6, color: sel? Colors.black : Colors.white), maxLines: 1),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ]),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Color(0xFF0F2810), border: Border.all(color: Colors.green, width: 1)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("AI SUGGESTION", style: TextStyle(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            Text(aiReason, style: TextStyle(fontSize: 9, color: Colors.white70)),
            SizedBox(height: 5),
            Wrap(
              spacing: 6,
              children: aiList.map((k) {
                return ActionChip(label: Text(filters[k]!["name"]!, style: TextStyle(fontSize: 8)), backgroundColor: selected.contains(k)? Colors.green : Colors.green.withOpacity(0.2), onPressed: () => toggle(k));
              }).toList(),
            ),
          ]),
        ),
        Container(
          height: 32,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.red, width: 1.5)),
          child: processing
             ? Stack(children: [
                  FractionallySizedBox(widthFactor: progress / 100, child: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: EdgeInsets.only(left: 8), child: Text("${progress.toStringAsFixed(0)}% Converting...", style: TextStyle(fontSize: 10, color: Colors.white)))),
                ])
              : Center(child: Text(status, style: TextStyle(fontSize: 10, color: Colors.white70))),
        ),
      ]),
    );
  }
}
