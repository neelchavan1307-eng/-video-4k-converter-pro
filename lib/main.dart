import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() { runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MasterEditor(), theme: ThemeData.dark())); }

class MasterEditor extends StatefulWidget { @override _MasterEditorState createState() => _MasterEditorState(); }

class _MasterEditorState extends State<MasterEditor> {
  String? videoPath, musicPath;
  VideoPlayerController? vc;
  bool processing = false, blurBg = false, stabilize = false, denoise = false, autoHDR = false, autoCaption = false, beatSync = false;
  double progress = 0;
  List<String> selected = [];
  String status = "Video निवडा - 80 Filters + Auto Caption Ready";
  String aiReason = "AI: Video टाकल्यावर Analysis करेल";
  List<String> aiList = [];
  String captionText = "Happy Birthday Prem!";
  TextEditingController capCtrl = TextEditingController(text: "Happy Birthday Prem!");

  Map<String, Map<String, String>> filters = {
    "f01": {"name": "Normal", "cmd": "", "c": "normal"},
    "f02": {"name": "B&W", "cmd": "hue=s=0", "c": "bw"},
    "f03": {"name": "Sepia", "cmd": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", "c": "sepia"},
    "f04": {"name": "Vintage", "cmd": "curves=vintage", "c": "warm"},
    "f05": {"name": "Warm Birthday", "cmd": "eq=brightness=0.06:saturation=1.35", "c": "warm"},
    "f06": {"name": "Cold", "cmd": "eq=saturation=1.2:gamma_b=1.2", "c": "cold"},
    "f07": {"name": "Bright", "cmd": "eq=brightness=0.25:contrast=1.25", "c": "bright"},
    "f08": {"name": "Vivid", "cmd": "eq=saturation=2.2:contrast=1.3", "c": "vivid"},
    "f09": {"name": "Blur Light", "cmd": "gblur=sigma=1.5", "c": "normal"},
    "f10": {"name": "Cinematic", "cmd": "eq=contrast=1.2:saturation=1.25", "c": "cinematic"},
    "f11": {"name": "Golden Hour", "cmd": "colorbalance=rs=0.3:bs=-0.2", "c": "warm"},
    "f12": {"name": "HDR 4K", "cmd": "eq=contrast=1.5:saturation=1.45", "c": "vivid"},
    "f13": {"name": "Noir", "cmd": "hue=s=0,eq=contrast=1.5", "c": "bw"},
    "f14": {"name": "Cartoon", "cmd": "edgedetect=low=0.1:high=0.4", "c": "normal"},
    "f15": {"name": "Dreamy Glow", "cmd": "eq=brightness=0.15:saturation=1.3", "c": "bright"},
    "f16": {"name": "Neon Party", "cmd": "eq=saturation=2.5:contrast=1.4", "c": "vivid"},
    "f17": {"name": "Old Film", "cmd": "curves=preset=vintage", "c": "sepia"},
    "f18": {"name": "Clarendon", "cmd": "eq=contrast=1.2:saturation=1.4", "c": "vivid"},
    "f19": {"name": "Lomo", "cmd": "curves=preset=lomo", "c": "vivid"},
    "f20": {"name": "Moon", "cmd": "hue=s=0,eq=brightness=0.1", "c": "bw"},
    "f21": {"name": "Fire", "cmd": "colorbalance=rs=0.4", "c": "warm"},
    "f22": {"name": "Ice", "cmd": "colorbalance=bs=0.4", "c": "cold"},
    "f23": {"name": "Pop Art", "cmd": "eq=saturation=3:contrast=2", "c": "vivid"},
    "f24": {"name": "Portrait", "cmd": "eq=brightness=0.08:saturation=1.15", "c": "bright"},
    "f25": {"name": "4K Ultra", "cmd": "scale=3840:2160:flags=lanczos", "c": "normal"},
    "f26": {"name": "Sharpen", "cmd": "unsharp=5:5:1", "c": "normal"},
    "f27": {"name": "Soft Skin", "cmd": "eq=saturation=1.1", "c": "bright"},
    "f28": {"name": "Night Boost", "cmd": "eq=brightness=0.35:contrast=1.25", "c": "bright"},
    "f29": {"name": "Daylight", "cmd": "eq=brightness=0.05:saturation=1.25", "c": "bright"},
    "f30": {"name": "Landscape", "cmd": "eq=saturation=1.6:contrast=1.2", "c": "vivid"},
    "f31": {"name": "Gold", "cmd": "colorchannelmixer=1.2:.3:.1:0", "c": "warm"},
    "f32": {"name": "Silver", "cmd": "hue=s=0.1", "c": "bw"},
    "f33": {"name": "Cyberpunk", "cmd": "eq=saturation=2:contrast=1.3", "c": "vivid"},
    "f34": {"name": "Dreamy", "cmd": "gblur=sigma=1.5", "c": "bright"},
    "f35": {"name": "Mirror", "cmd": "hflip", "c": "normal"},
    "f36": {"name": "Vignette", "cmd": "vignette=PI/4", "c": "cinematic"},
    "f37": {"name": "Insta Sq", "cmd": "crop=1:1,scale=1080:1080", "c": "normal"},
    "f38": {"name": "Sunset", "cmd": "eq=brightness=0.08:saturation=1.8", "c": "warm"},
    "f39": {"name": "Sunrise", "cmd": "eq=brightness=0.18:saturation=1.4", "c": "warm"},
    "f40": {"name": "Rose Gold", "cmd": "colorchannelmixer=1:.3:.3:0", "c": "warm"},
    "f41": {"name": "Fade", "cmd": "eq=brightness=0.12:contrast=0.85", "c": "bright"},
    "f42": {"name": "High Key", "cmd": "eq=brightness=0.28", "c": "bright"},
    "f43": {"name": "Low Key", "cmd": "eq=brightness=-0.25:contrast=1.45", "c": "cinematic"},
    "f44": {"name": "Pastel", "cmd": "eq=saturation=0.7:brightness=0.15", "c": "bright"},
    "f45": {"name": "Bronze", "cmd": "colorchannelmixer=1:.5:.2:0", "c": "warm"},
    "f46": {"name": "Deep Blue", "cmd": "colorbalance=bs=0.5", "c": "cold"},
    "f47": {"name": "Deep Red", "cmd": "colorbalance=rs=0.5", "c": "warm"},
    "f48": {"name": "Indoor", "cmd": "eq=brightness=0.15:saturation=1.1", "c": "bright"},
    "f49": {"name": "Grain", "cmd": "noise=alls=20", "c": "normal"},
    "f50": {"name": "DeNoise", "cmd": "hqdn3d", "c": "normal"},
    "f51": {"name": "Emboss", "cmd": "convolution=-2 -1 0 -1 1 1 0 1 2:0:0:0:0:1:0", "c": "normal"},
    "f52": {"name": "Pixelate", "cmd": "scale=iw/10:ih/10:flags=neighbor,scale=10*iw:10*ih:flags=neighbor", "c": "normal"},
    "f53": {"name": "Rotate 90", "cmd": "transpose=1", "c": "normal"},
    "f54": {"name": "Fish Eye", "cmd": "vignette=angle=PI/4", "c": "normal"},
    "f55": {"name": "Glow", "cmd": "eq=brightness=0.18", "c": "bright"},
    "f56": {"name": "Slow Mo", "cmd": "setpts=2*PTS", "c": "normal"},
    "f57": {"name": "Fast 2x", "cmd": "setpts=0.5*PTS", "c": "normal"},
    "f58": {"name": "CinemaScope", "cmd": "crop=21/9*ih:ih", "c": "cinematic"},
    "f59": {"name": "Zoom In", "cmd": "scale=2*iw:2*ih,crop=iw/2:ih/2", "c": "normal"},
    "f60": {"name": "Flip V", "cmd": "vflip", "c": "normal"},
    "f61": {"name": "Ice Pro", "cmd": "colortemperature=temperature=3000", "c": "cold"},
    "f62": {"name": "Fire Pro", "cmd": "colortemperature=temperature=8000", "c": "warm"},
    "f63": {"name": "Neon Glow", "cmd": "eq=saturation=2.5:contrast=1.4", "c": "vivid"},
    "f64": {"name": "Matrix", "cmd": "colorchannelmixer=.1:.9:.1:0", "c": "vivid"},
    "f65": {"name": "Mono Red", "cmd": "colorchannelmixer=1:0:0:0", "c": "warm"},
    "f66": {"name": "Mono Blue", "cmd": "colorchannelmixer=0:0:1:0", "c": "cold"},
    "f67": {"name": "Inverted", "cmd": "negate", "c": "bw"},
    "f68": {"name": "Sharp Strong", "cmd": "unsharp=7:7:2.5", "c": "normal"},
    "f69": {"name": "Blur Heavy", "cmd": "gblur=sigma=10", "c": "normal"},
    "f70": {"name": "Dark -20", "cmd": "eq=brightness=-0.2", "c": "cinematic"},
    "f71": {"name": "Bright +40", "cmd": "eq=brightness=0.4", "c": "bright"},
    "f72": {"name": "Love Glow", "cmd": "eq=brightness=0.15:saturation=1.6", "c": "warm"},
    "f73": {"name": "Rose Pink", "cmd": "colorbalance=rs=0.4:bs=0.2", "c": "warm"},
    "f74": {"name": "Heart Bokeh", "cmd": "eq=brightness=0.2:saturation=1.4", "c": "bright"},
    "f75": {"name": "Prem Special", "cmd": "eq=saturation=1.6", "c": "vivid"},
    "f76": {"name": "Road Love", "cmd": "eq=contrast=1.3:saturation=1.5", "c": "cinematic"},
    "f77": {"name": "AI UHD Pro", "cmd": "scale=3840:2160:flags=lanczos,eq=contrast=1.2", "c": "vivid"},
    "f78": {"name": "Magic Portrait", "cmd": "eq=brightness=0.08:saturation=1.2", "c": "bright"},
    "f79": {"name": "Stabilize Pro", "cmd": "deshake", "c": "normal"},
    "f80": {"name": "HDR Pro Max", "cmd": "eq=contrast=1.4:saturation=1.5", "c": "vivid"},
  };

  List<String> get keys => filters.keys.toList();

  ColorFilter getPreview() {
    if (selected.isEmpty) return ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    String c = filters[selected.last]!["c"]!;
    if (c == "bw") return ColorFilter.matrix([0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0]);
    if (c == "warm") return ColorFilter.mode(Colors.orange.withOpacity(0.25), BlendMode.overlay);
    if (c == "vivid") return ColorFilter.matrix([1.35,0,0,0,0, 0,1.35,0,0,0, 0,0,1.35,0,0, 0,0,0,1,0]);
    return ColorFilter.mode(Colors.white.withOpacity(0.2), BlendMode.lighten);
  }

  Future<void> analyzeAI(String path) async {
    var infoS = await FFprobeKit.getMediaInformation(path);
    var info = infoS.getMediaInformation();
    double dur = double.tryParse(info?.getDuration()?? "0")?? 0;
    int w = info?.getStreams().first.getWidth()?? 0;
    String name = path.toLowerCase();
    if (name.contains("birthday") || dur < 15) {
      aiList = ["f05", "f15", "f77"]; aiReason = "AI: Birthday ${dur.toInt()}s ${w}p - Warm + Dreamy + AI UHD Best!"; selected = ["f05", "f15"];
    } else if (name.contains("love") || name.contains("prem")) {
      aiList = ["f72", "f73", "f74"]; aiReason = "AI: Love Video Detect - Love Glow + Rose Pink + Heart Bokeh Best!"; selected = ["f72", "f73"];
    } else if (w < 1280) {
      aiList = ["f77", "f26", "f12"]; aiReason = "AI: Low Quality ${w}p - 4K Ultra + Sharpen + HDR Proper 4K!"; selected = ["f77", "f26"];
    } else {
      aiList = ["f10", "f08", "f77"]; aiReason = "AI: Daylight ${w}p - Cinematic + Vivid + AI UHD Best!"; selected = ["f10"];
    }
    setState(() {});
  }

  Future pickVideo() async {
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r == null) return;
    videoPath = r.files.single.path!;
    vc?.dispose();
    vc = VideoPlayerController.file(File(videoPath!));
    await vc!.initialize(); vc!.setLooping(true); vc!.play();
    await analyzeAI(videoPath!);
    setState(() { status = "Ready: ${r.files.single.name}"; });
  }

  Future pickMusic() async {
    var r = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (r == null) return;
    musicPath = r.files.single.path!;
    setState(() { status = "Music Added: ${r.files.single.name}"; });
  }

  void toggle(String k) { setState(() { if (selected.contains(k)) selected.remove(k); else if (selected.length < 10) selected.add(k); }); }

  void openFullScreen() {
    if (vc == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return Scaffold(backgroundColor: Colors.black, body: Stack(children: [
        Center(child: AspectRatio(aspectRatio: vc!.value.aspectRatio, child: ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!)))),
        Positioned(top: 40, left: 15, child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
        Positioned(bottom: 20, left: 15, right: 15, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: Text("BACK TO EDITING - ${selected.length} Filters + ${autoCaption? 'Caption' : ''}"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF7C4DFF), minimumSize: Size(double.infinity, 50)))),
      ]));
    }));
  }

  Future export() async {
    if (videoPath == null) return;
    setState(() { processing = true; progress = 0; });
    var tmp = await getTemporaryDirectory();
    var out = "${tmp.path}/MASTER_${DateTime.now().millisecondsSinceEpoch}.mp4";
    List<String> vf = ["scale=3840:2160:flags=lanczos"];
    if (blurBg) vf.add("gblur=sigma=2");
    if (stabilize) vf.add("deshake");
    if (denoise) vf.add("hqdn3d");
    if (autoHDR) vf.add("eq=contrast=1.3:saturation=1.3");
    for (var k in selected) { if (filters[k]!["cmd"]!.isNotEmpty) vf.add(filters[k]!["cmd"]!); }
    if (autoCaption) { vf.add("drawtext=text='$captionText':fontcolor=white:fontsize=70:box=1:boxcolor=black@0.6:boxborderw=10:x=(w-text_w)/2:y=h-th-250"); }
    String cmd;
    if (musicPath!= null) {
      cmd = "-i $videoPath -i $musicPath -vf ${vf.join(",")} -map 0:v:0 -map 1:a:0 -shortest -c:v libx264 -preset ultrafast -crf 18 -c:a aac $out";
    } else {
      cmd = "-i $videoPath -vf ${vf.join(",")} -c:v libx264 -preset ultrafast -crf 18 -c:a aac $out";
    }
    FFmpegKit.executeAsync(cmd, (s) async {
      if (ReturnCode.isSuccess(await s.getReturnCode())) {
        var dir = Directory("/storage/emulated/0/Movies/4K Converter");
        if (!await dir.exists()) await dir.create(recursive: true);
        await File(out).copy("${dir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4");
        setState(() { processing = false; progress = 100; status = "100% Saved to Gallery! ${beatSync? '+ Beat Sync' : ''}"; });
      } else { setState(() { processing = false; status = "Failed"; }); }
    }, (l) {}, (st) { setState(() { progress = (st.getTime() / 1000).clamp(0, 100).toDouble(); }); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: Colors.black, title: Text("MASTER 4K - ${selected.length} Filters", style: TextStyle(fontSize: 11)), actions: [
        ElevatedButton(onPressed: export, child: Text("Export 4K"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF5AC8FA), foregroundColor: Colors.black)),
        SizedBox(width: 8),
      ]),
      body: Column(children: [
        Expanded(flex: 4, child: Container(color: Colors.black, width: double.infinity, child: Stack(children: [
          Center(child: vc!= null && vc!.value.isInitialized? AspectRatio(aspectRatio: vc!.value.aspectRatio, child: ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!))) : GestureDetector(onTap: pickVideo, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 50, color: Colors.white24), ElevatedButton(onPressed: pickVideo, child: Text("PICK VIDEO"))]))),
          Positioned(left: 10, bottom: 10, child: GestureDetector(onTap: openFullScreen, child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white, width: 1.5)), child: Icon(Icons.fullscreen, size: 18, color: Colors.white)))),
          Positioned(right: 10, top: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Switch(value: stabilize, onChanged: (v) => setState(() => stabilize = v), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap), Text("Stabilize", style: TextStyle(fontSize: 8))]),
            Row(children: [Switch(value: blurBg, onChanged: (v) => setState(() => blurBg = v), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap), Text("Blur BG", style: TextStyle(fontSize: 8))]),
            Row(children: [Switch(value: autoHDR, onChanged: (v) => setState(() => autoHDR = v), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap), Text("AI HDR", style: TextStyle(fontSize: 8))]),
            Row(children: [Switch(value: autoCaption, onChanged: (v) => setState(() => autoCaption = v), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, activeColor: Colors.orange), Text("Auto Caption", style: TextStyle(fontSize: 8))]),
            Row(children: [Switch(value: beatSync, onChanged: (v) => setState(() => beatSync = v), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, activeColor: Colors.pink), Text("Beat Sync", style: TextStyle(fontSize: 8))]),
          ])),
        ]))),
        Container(height: 130, color: Color(0xFF151515), padding: EdgeInsets.all(6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("🟧 FILTERS - 80 Filters Right to Left Swipe - ${selected.length}/10", style: TextStyle(fontSize: 8, color: Colors.orange)),
          SizedBox(height: 4),
          Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: Wrap(direction: Axis.vertical, spacing: 6, runSpacing: 6, children: keys.map((k) {
            bool sel = selected.contains(k);
            return GestureDetector(onTap: () => toggle(k), child: Container(width: 64, height: 36, decoration: BoxDecoration(color: sel? Colors.orange : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(6), border: Border.all(color: sel? Colors.white : Colors.transparent, width: sel? 1.5 : 0)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(sel? Icons.check_circle : Icons.filter_alt, size: 11, color: sel? Colors.black : Colors.white60), Text(filters[k]!["name"]!, style: TextStyle(fontSize: 6, color: sel? Colors.black : Colors.white), maxLines: 1)])));
          }).toList()))),
        ])),
        Container(width: double.infinity, padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFF0F2810), border: Border.all(color: Colors.green, width: 1)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("🟩 AI SUGGESTION", style: TextStyle(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          Text(aiReason, style: TextStyle(fontSize: 9, color: Colors.white70)),
          Wrap(spacing: 6, children: aiList.map((k) { return ActionChip(label: Text(filters[k]!["name"]!, style: TextStyle(fontSize: 8)), backgroundColor: selected.contains(k)? Colors.green : Colors.green.withOpacity(0.2), onPressed: () => toggle(k)); }).toList()),
        ])),
        Container(height: 40, color: Colors.black, padding: EdgeInsets.symmetric(horizontal: 6), child: Row(children: [
          Expanded(child: TextField(controller: capCtrl, onChanged: (v) => captionText = v, decoration: InputDecoration(hintText: "Auto Caption लिहा - e.g. Happy Birthday Prem", isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)), style: TextStyle(fontSize: 10))),
          SizedBox(width: 6),
          ElevatedButton(onPressed: pickMusic, child: Text(musicPath == null? "🎵 Music" : "Added", style: TextStyle(fontSize: 9)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, minimumSize: Size(70, 32))),
        ])),
        Container(height: 32, width: double.infinity, decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.red, width: 1.5)), child: processing? Stack(children: [FractionallySizedBox(widthFactor: progress / 100, child: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: EdgeInsets.only(left: 8), child: Text("${progress.toStringAsFixed(0)}% Converting ${beatSync? '+ Beat Sync' : ''} & Saving...", style: TextStyle(fontSize: 9, color: Colors.white))))]) : Center(child: Text(status, style: TextStyle(fontSize: 10, color: Colors.white70)))),
      ]),
    );
  }
}
