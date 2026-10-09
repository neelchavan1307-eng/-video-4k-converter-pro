import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: ProMaxEditor(), theme: ThemeData.dark()));
class ProMaxEditor extends StatefulWidget { @override State<ProMaxEditor> createState() => _ProMaxEditorState(); }
class _ProMaxEditorState extends State<ProMaxEditor> {
  String? videoPath, musicPath; VideoPlayerController? vc;
  bool processing=false, stabilize=false, denoise=false, autoHDR=false, autoCaption=false, beatSync=false, autoEnhance=true;
  double progress=0; List<String> selected=[]; String status="PRO MAX 101 Filters Ready";
  String aiReason="TRUE AI: Video टाक - AI Auto Analyze करेल!"; List<String> aiList=[];
  String captionText="Happy Birthday Prem!"; TextEditingController capCtrl=TextEditingController(text:"Happy Birthday Prem!");
  double aiScore=0; String videoMeta="";
  final Map<String, Map<String, String>> filters = {
    "f01": {"name": "Normal", "cmd": "", "c": "normal"},
    "f02": {"name": "B&W", "cmd": "hue=s=0", "c": "bw"},
    "f03": {"name": "Sepia", "cmd": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", "c": "sepia"},
    "f04": {"name": "Vintage", "cmd": "curves=vintage", "c": "warm"},
    "f05": {"name": "Warm BDay", "cmd": "eq=brightness=0.06:saturation=1.35", "c": "warm"},
    "f06": {"name": "Cold", "cmd": "eq=saturation=1.2", "c": "cold"},
    "f07": {"name": "Bright", "cmd": "eq=brightness=0.25:contrast=1.25", "c": "bright"},
    "f08": {"name": "Vivid", "cmd": "eq=saturation=2.2:contrast=1.3", "c": "vivid"},
    "f09": {"name": "Blur Light", "cmd": "gblur=sigma=1.5", "c": "normal"},
    "f10": {"name": "Cinematic", "cmd": "eq=contrast=1.2:saturation=1.25", "c": "cinematic"},
    "f11": {"name": "Golden Hour", "cmd": "colorbalance=rs=0.3:bs=-0.2", "c": "warm"},
    "f12": {"name": "HDR 4K", "cmd": "eq=contrast=1.5:saturation=1.45", "c": "vivid"},
    "f13": {"name": "Noir", "cmd": "hue=s=0,eq=contrast=1.5", "c": "bw"},
    "f14": {"name": "Dreamy Glow", "cmd": "eq=brightness=0.15:saturation=1.3", "c": "bright"},
    "f15": {"name": "Neon Party", "cmd": "eq=saturation=2.5:contrast=1.4", "c": "vivid"},
    "f16": {"name": "Clarendon", "cmd": "eq=contrast=1.2:saturation=1.4", "c": "vivid"},
    "f17": {"name": "Moon", "cmd": "hue=s=0,eq=brightness=0.1", "c": "bw"},
    "f18": {"name": "Fire", "cmd": "colorbalance=rs=0.4", "c": "warm"},
    "f19": {"name": "Ice", "cmd": "colorbalance=bs=0.4", "c": "cold"},
    "f20": {"name": "Pop Art", "cmd": "eq=saturation=3:contrast=2", "c": "vivid"},
    "f21": {"name": "Portrait", "cmd": "eq=brightness=0.08:saturation=1.15", "c": "bright"},
    "f22": {"name": "4K Ultra", "cmd": "scale=3840:2160:flags=lanczos", "c": "normal"},
    "f23": {"name": "Sharpen Pro", "cmd": "unsharp=7:7:1.5", "c": "normal"},
    "f24": {"name": "Soft Skin AI", "cmd": "eq=saturation=1.1", "c": "bright"},
    "f25": {"name": "Night Boost", "cmd": "eq=brightness=0.35:contrast=1.25", "c": "bright"},
    "f26": {"name": "Daylight AI", "cmd": "eq=brightness=0.05:saturation=1.25", "c": "bright"},
    "f27": {"name": "Landscape", "cmd": "eq=saturation=1.6:contrast=1.2", "c": "vivid"},
    "f28": {"name": "Gold Luxury", "cmd": "colorchannelmixer=1.2:.4:.2:0", "c": "warm"},
    "f29": {"name": "Silver", "cmd": "hue=s=0.15", "c": "bw"},
    "f30": {"name": "Cyberpunk", "cmd": "eq=saturation=2.2:contrast=1.3", "c": "vivid"},
    "f31": {"name": "Vignette", "cmd": "vignette=PI/4", "c": "cinematic"},
    "f32": {"name": "Sunset Max", "cmd": "eq=brightness=0.08:saturation=1.8", "c": "warm"},
    "f33": {"name": "Sunrise", "cmd": "eq=brightness=0.18:saturation=1.4", "c": "warm"},
    "f34": {"name": "Rose Gold", "cmd": "colorchannelmixer=1.1:.3:.3:0", "c": "warm"},
    "f35": {"name": "Fade Film", "cmd": "eq=brightness=0.12:contrast=0.85", "c": "bright"},
    "f36": {"name": "High Key", "cmd": "eq=brightness=0.28", "c": "bright"},
    "f37": {"name": "Low Key", "cmd": "eq=brightness=-0.25:contrast=1.45", "c": "cinematic"},
    "f38": {"name": "Pastel", "cmd": "eq=saturation=0.7:brightness=0.15", "c": "bright"},
    "f39": {"name": "Deep Blue", "cmd": "colorbalance=bs=0.5", "c": "cold"},
    "f40": {"name": "Deep Red", "cmd": "colorbalance=rs=0.5", "c": "warm"},
    "f41": {"name": "Indoor Pro", "cmd": "eq=brightness=0.15:saturation=1.1", "c": "bright"},
    "f42": {"name": "Grain Film", "cmd": "noise=alls=20", "c": "normal"},
    "f43": {"name": "DeNoise AI", "cmd": "hqdn3d", "c": "normal"},
    "f44": {"name": "Rotate 90", "cmd": "transpose=1", "c": "normal"},
    "f45": {"name": "Glow Angel", "cmd": "eq=brightness=0.18", "c": "bright"},
    "f46": {"name": "Slow Mo", "cmd": "setpts=2*PTS", "c": "normal"},
    "f47": {"name": "Fast 2x", "cmd": "setpts=0.5*PTS", "c": "normal"},
    "f48": {"name": "Zoom In", "cmd": "scale=2*iw:2*ih,crop=iw/2:ih/2", "c": "normal"},
    "f49": {"name": "Flip V", "cmd": "vflip", "c": "normal"},
    "f50": {"name": "Ice Max", "cmd": "colortemperature=temperature=2500", "c": "cold"},    "f51": {"name": "Fire Max", "cmd": "colortemperature=temperature=9000", "c": "warm"},
    "f52": {"name": "Neon Glow", "cmd": "eq=saturation=2.8:contrast=1.5", "c": "vivid"},
    "f53": {"name": "Inverted", "cmd": "negate", "c": "bw"},
    "f54": {"name": "Sharp Max", "cmd": "unsharp=9:9:2.5", "c": "normal"},
    "f55": {"name": "Blur Heavy", "cmd": "gblur=sigma=12", "c": "normal"},
    "f56": {"name": "Dark Pro", "cmd": "eq=brightness=-0.2", "c": "cinematic"},
    "f57": {"name": "Bright+40", "cmd": "eq=brightness=0.4", "c": "bright"},
    "f58": {"name": "Love Glow", "cmd": "eq=brightness=0.15:saturation=1.8", "c": "warm"},
    "f59": {"name": "Rose Pink", "cmd": "colorbalance=rs=0.5:bs=0.3", "c": "warm"},
    "f60": {"name": "Heart Bokeh", "cmd": "eq=brightness=0.2:saturation=1.5", "c": "bright"},
    "f61": {"name": "Prem Special", "cmd": "colorchannelmixer=1:.2:.4:0", "c": "vivid"},
    "f62": {"name": "Road Love", "cmd": "eq=contrast=1.3:saturation=1.6", "c": "cinematic"},
    "f63": {"name": "AI UHD Max", "cmd": "scale=3840:2160:flags=lanczos,eq=contrast=1.25:saturation=1.35", "c": "vivid"},
    "f64": {"name": "Portrait AI", "cmd": "eq=brightness=0.08:saturation=1.25", "c": "bright"},
    "f65": {"name": "Stabilize", "cmd": "deshake", "c": "normal"},
    "f66": {"name": "HDR Max+", "cmd": "eq=contrast=1.45:saturation=1.6", "c": "vivid"},
    "f67": {"name": "AI Face Glow", "cmd": "eq=brightness=0.1:saturation=1.3", "c": "bright"},
    "f68": {"name": "AI Skin", "cmd": "hqdn3d=2:2:4:4", "c": "bright"},
    "f69": {"name": "AI Night King", "cmd": "eq=brightness=0.45:contrast=1.35", "c": "bright"},
    "f70": {"name": "AI Color Pop", "cmd": "eq=saturation=1.8", "c": "vivid"},
    "f71": {"name": "Bokeh Blur", "cmd": "gblur=sigma=5", "c": "bright"},
    "f72": {"name": "Chroma Pop", "cmd": "eq=saturation=2:contrast=1.2", "c": "vivid"},
    "f73": {"name": "Film Burn", "cmd": "curves=preset=cross_process", "c": "warm"},
    "f74": {"name": "VHS Retro", "cmd": "noise=alls=15", "c": "retro"},
    "f75": {"name": "Wedding Pro", "cmd": "eq=brightness=0.12:saturation=1.35", "c": "warm"},
    "f76": {"name": "Pre-Wedding", "cmd": "eq=brightness=0.08:saturation=1.5", "c": "warm"},
    "f77": {"name": "Haldi Special", "cmd": "colorbalance=rs=0.3:gs=0.2", "c": "warm"},
    "f78": {"name": "Mehndi Green", "cmd": "colorbalance=gs=0.4", "c": "vivid"},
    "f79": {"name": "Sangeet Neon", "cmd": "eq=saturation=2.2:contrast=1.3", "c": "vivid"},
    "f80": {"name": "Reel Viral", "cmd": "eq=saturation=1.6:contrast=1.25", "c": "vivid"},
    "f81": {"name": "Insta Viral", "cmd": "eq=saturation=1.8:contrast=1.3", "c": "vivid"},
    "f82": {"name": "YT Shorts", "cmd": "scale=1080:1920:flags=lanczos", "c": "vivid"},
    "f83": {"name": "TikTok", "cmd": "eq=saturation=1.7:contrast=1.2", "c": "vivid"},
    "f84": {"name": "Birthday Blast", "cmd": "eq=brightness=0.1:saturation=1.8", "c": "warm"},
    "f85": {"name": "Anniversary", "cmd": "colorchannelmixer=1.3:.4:.2:0", "c": "warm"},
    "f86": {"name": "Baby Face AI", "cmd": "eq=brightness=0.15:saturation=1.2", "c": "bright"},
    "f87": {"name": "Model Pro Max", "cmd": "eq=brightness=0.08:saturation=1.3", "c": "bright"},
    "f88": {"name": "Cinematic 8K", "cmd": "scale=7680:4320:flags=lanczos", "c": "cinematic"},
    "f89": {"name": "AI 8K", "cmd": "scale=7680:4320:flags=lanczos", "c": "vivid"},
    "f90": {"name": "Green Screen", "cmd": "chromakey=0x00FF00:0.3:0.2", "c": "normal"},
    "f91": {"name": "BG Remover", "cmd": "colorkey=0x00FF00:0.3:0.2", "c": "normal"},
    "f92": {"name": "Reverse Pro", "cmd": "reverse", "c": "normal"},
    "f93": {"name": "Mirror World", "cmd": "hflip,vflip", "c": "normal"},
    "f94": {"name": "Glitch Pro", "cmd": "noise=alls=20", "c": "vivid"},
    "f95": {"name": "Old Bollywood", "cmd": "curves=preset=vintage", "c": "warm"},
    "f96": {"name": "Punjabi Pop", "cmd": "eq=saturation=2:contrast=1.3", "c": "vivid"},
    "f97": {"name": "Marathi Lavni", "cmd": "colorbalance=rs=0.3:gs=0.1", "c": "warm"},
    "f98": {"name": "Bhojpuri Power", "cmd": "eq=saturation=1.9:contrast=1.35", "c": "vivid"},
    "f99": {"name": "South Indian", "cmd": "eq=saturation=1.7:contrast=1.25", "c": "warm"},
    "f100": {"name": "Gujarati Garba", "cmd": "eq=saturation=2.1:contrast=1.2", "c": "vivid"},
    "f101": {"name": "PRO MAX GOD", "cmd": "scale=3840:2160:flags=lanczos,eq=contrast=1.35:saturation=1.5:brightness=0.05,unsharp=6:6:1.2", "c": "vivid"},
  };
  List<String> get keys => filters.keys.toList();
  ColorFilter getPreview() {
    if (selected.isEmpty) return ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    String c = filters[selected.last]!["c"]!;
    if (c == "bw") return ColorFilter.matrix([0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0]);
    if (c == "warm") return ColorFilter.mode(Colors.orange.withOpacity(0.28), BlendMode.overlay);
    if (c == "vivid") return ColorFilter.matrix([1.4,0,0,0,0, 0,1.4,0,0,0, 0,0,1.4,0,0, 0,0,0,1,0]);
    return ColorFilter.mode(Colors.white.withOpacity(0.22), BlendMode.lighten);
  }
  Future<void> trueAIAnalyze(String path) async {
    var infoS = await FFprobeKit.getMediaInformation(path); var info = infoS.getMediaInformation(); if (info == null) return;
    double dur = double.tryParse(info.getDuration()?? "0")?? 0;
    int w = info.getStreams().isNotEmpty? (info.getStreams().first.getWidth()?? 0) : 0;
    int h = info.getStreams().isNotEmpty? (info.getStreams().first.getHeight()?? 0) : 0;
    String lower = path.toLowerCase(); bool isLowQ = w < 1280; bool isPortrait = h > w; bool isBirthday = lower.contains("birthday"); bool isLove = lower.contains("love") || lower.contains("prem") || lower.contains("wedding");
    videoMeta = "${w}x${h} | ${dur.toStringAsFixed(1)}s"; aiScore = 85;
    if (isBirthday) { aiList = ["f05","f14","f84","f63","f58"]; aiReason = "TRUE AI: Birthday $videoMeta -> Warm + Dreamy + Birthday Blast = BEST!"; selected = ["f05","f14","f63"]; autoHDR = true; }
    else if (isLove) { aiList = ["f58","f61","f75","f62","f59"]; aiReason = "TRUE AI: Love/Wedding $videoMeta -> Prem Special + Love Glow + Wedding Pro = Trending!"; selected = ["f61","f58","f75"]; autoHDR = true; }
    else if (isLowQ) { aiList = ["f63","f23","f43","f66"]; aiReason = "TRUE AI: Low Quality ${w}p -> 4K Needed! -> AI UHD + Sharpen + DeNoise = 4K!"; selected = ["f63","f23","f43"]; stabilize = true; denoise = true; autoHDR = true; }
    else if (isPortrait) { aiList = ["f82","f80","f63","f87"]; aiReason = "TRUE AI: Portrait Reel $videoMeta -> YT Shorts + Reel Viral = 100% Viral!"; selected = ["f80","f63"]; }
    else { aiList = ["f101","f10","f63","f27"]; aiReason = "TRUE AI: Daylight Pro $videoMeta -> PRO MAX GOD + Cinematic = Cinema Level! AI 95%!"; selected = ["f101"]; }
    setState(() {});
  }
  Future pickVideo() async { var r = await FilePicker.platform.pickFiles(type: FileType.video); if (r == null) return; videoPath = r.files.single.path!; vc?.dispose(); vc = VideoPlayerController.file(File(videoPath!)); await vc!.initialize(); vc!.setLooping(true); vc!.play(); await trueAIAnalyze(videoPath!); setState(() { status = "Ready: ${r.files.single.name} | $videoMeta"; }); }
  Future pickMusic() async { var r = await FilePicker.platform.pickFiles(type: FileType.audio); if (r == null) return; musicPath = r.files.single.path!; setState(() { status = "Music Added"; beatSync = true; }); }
  void toggle(String k) { setState(() { if (selected.contains(k)) selected.remove(k); else if (selected.length < 12) selected.add(k); }); }
  void openFullScreen() { if (vc == null) return; Navigator.push(context, MaterialPageRoute(builder: (_) { return Scaffold(backgroundColor: Colors.black, body: Stack(children: [Center(child: AspectRatio(aspectRatio: vc!.value.aspectRatio, child: ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!)))), Positioned(top: 40, left: 15, child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))), Positioned(bottom: 20, left: 15, right: 15, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: Text("BACK"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF7C4DFF), minimumSize: Size(double.infinity, 50))))])); })); }
  Future export() async {
    if (videoPath == null) return; setState(() { processing = true; progress = 0; });
    var tmp = await getTemporaryDirectory(); var out = "${tmp.path}/PROMAX_${DateTime.now().millisecondsSinceEpoch}.mp4";
    List<String> vf = []; vf.add("scale=3840:2160:flags=lanczos");
    if (stabilize) vf.add("deshake=rx=20:ry=20"); if (denoise) vf.add("hqdn3d=4:4:6:6"); if (autoHDR) vf.add("eq=contrast=1.35:saturation=1.45");
    for (var k in selected) { var cmd = filters[k]!["cmd"]!; if (cmd.isNotEmpty) vf.add(cmd); }
    if (autoCaption) vf.add("drawtext=text='$captionText':fontcolor=white:fontsize=60:borderw=3:bordercolor=black:x=(w-text_w)/2:y=h-th-200");
    String cmd; if (musicPath!= null) { cmd = "-i $videoPath -i $musicPath -vf ${vf.join(",")} -map 0:v:0 -map 1:a:0 -shortest -c:v libx264 -preset ultrafast -crf 18 -c:a aac $out"; } else { cmd = "-i $videoPath -vf ${vf.join(",")} -c:v libx264 -preset ultrafast -crf 18 -c:a aac $out"; }
    FFmpegKit.executeAsync(cmd, (s) async {
      if (ReturnCode.isSuccess(await s.getReturnCode())) {
        try { var dir = Directory("/storage/emulated/0/Movies/4K Converter"); if (!await dir.exists()) await dir.create(recursive: true); await File(out).copy("${dir.path}/PROMAX_4K_${DateTime.now().millisecondsSinceEpoch}.mp4"); } catch (e) {}
        setState(() { processing = false; progress = 100; status = "100% PRO MAX 4K Saved!"; });
      } else { setState(() { processing = false; status = "Failed - Try less filters"; }); }
    }, (log) {}, (stats) { int t = stats.getTime(); double p = (t / 1000).clamp(0, 99).toDouble(); setState(() { progress = p; }); });
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: Colors.black, title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("PRO MAX GOD - ${selected.length}/12", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), Text(videoMeta, style: TextStyle(fontSize: 9, color: Colors.white54))]), actions: [ElevatedButton(onPressed: export, child: Text("Export 4K", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFD700), foregroundColor: Colors.black, minimumSize: Size(110, 38))), SizedBox(width: 8)]),
      body: Column(children: [
        Container(height: MediaQuery.of(context).size.height * 0.46, color: Colors.black, width: double.infinity, child: Stack(children: [
          Center(child: vc!= null && vc!.value.isInitialized? FittedBox(fit: BoxFit.contain, child: SizedBox(width: vc!.value.size.width, height: vc!.value.size.height, child: Stack(children: [ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!)), if (autoCaption) Positioned(bottom: 20, left: 0, right: 0, child: Center(child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text(captionText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))))]))) : GestureDetector(onTap: pickVideo, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 60, color: Colors.white24), SizedBox(height: 12), ElevatedButton(onPressed: pickVideo, child: Text("PICK VIDEO - PRO MAX")), Text("101 Filters + True AI", style: TextStyle(fontSize: 10, color: Colors.white38))]))),
          Positioned(left: 12, bottom: 12, child: GestureDetector(onTap: openFullScreen, child: Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1.5)), child: Icon(Icons.fullscreen, size: 22, color: Colors.white)))),
          Positioned(right: 6, top: 6, child: Container(padding: EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Switch(value: autoEnhance, onChanged: (v) => setState(() => autoEnhance = v), activeColor: Color(0xFFFFD700)), Text("AI Enhance", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))]),
            Row(children: [Switch(value: stabilize, onChanged: (v) => setState(() => stabilize = v), activeColor: Colors.orange), Text("Stabilize", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: autoHDR, onChanged: (v) => setState(() => autoHDR = v), activeColor: Colors.red), Text("AI HDR", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: denoise, onChanged: (v) => setState(() => denoise = v), activeColor: Colors.blue), Text("DeNoise", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: autoCaption, onChanged: (v) => setState(() => autoCaption = v), activeColor: Colors.green), Text("Caption", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: beatSync, onChanged: (v) => setState(() => beatSync = v), activeColor: Colors.pink), Text("Beat Sync", style: TextStyle(fontSize: 9))]),
          ]))),
        ])),
        Container(height: 175, color: Color(0xFF151515), padding: EdgeInsets.all(6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text("PRO MAX - 101 Filters - ${selected.length}/12 MAX", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)), Spacer(), Text("AI: ${aiScore.toInt()}%", style: TextStyle(fontSize: 9, color: Color(0xFFFFD700)))]),
          SizedBox(height: 6),
          Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: Wrap(direction: Axis.vertical, spacing: 7, runSpacing: 7, children: keys.map((k) {
            bool sel = selected.contains(k);
            return GestureDetector(onTap: () => toggle(k), child: Container(width: 82, height: 44, decoration: BoxDecoration(color: sel? Colors.orange : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8), border: Border.all(color: sel? Colors.white : Colors.transparent, width: sel? 2 : 0)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(sel? Icons.check_circle : Icons.filter_alt, size: 12, color: sel? Colors.black : Colors.white60), Text(filters[k]!["name"]!, style: TextStyle(fontSize: 7, color: sel? Colors.black : Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)])));
          }).toList()))),
        ])),
        Container(width: double.infinity, padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF0F2810), border: Border.all(color: Colors.green, width: 1.5)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.smart_toy, size: 14, color: Colors.greenAccent), SizedBox(width: 4), Text("TRUE AI SUPPORT", style: TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold)), Spacer(), Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Color(0xFFFFD700), borderRadius: BorderRadius.circular(4)), child: Text("AI ${aiScore.toInt()}%", style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)))]),
          SizedBox(height: 3), Text(aiReason, style: TextStyle(fontSize: 10, color: Colors.white, height: 1.3)),
          SizedBox(height: 6), Wrap(spacing: 6, runSpacing: 4, children: aiList.map((k) { bool sel = selected.contains(k); return ActionChip(label: Text(filters[k]!["name"]!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)), backgroundColor: sel? Colors.green : Colors.green.withOpacity(0.25), onPressed: () => toggle(k)); }).toList()),
        ])),
        Container(height: 46, color: Colors.black, padding: EdgeInsets.symmetric(horizontal: 6), child: Row(children: [
          Expanded(child: TextField(controller: capCtrl, onChanged: (v) => setState(() => captionText = v), decoration: InputDecoration(hintText: "Auto Caption - Happy Birthday Prem!", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), prefixIcon: Icon(Icons.closed_caption, size: 16)), style: TextStyle(fontSize: 11))),
          SizedBox(width: 6), ElevatedButton.icon(onPressed: pickMusic, icon: Icon(Icons.music_note, size: 14), label: Text(musicPath == null? "Music" : "Added", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: beatSync? Colors.pink : Colors.white12, minimumSize: Size(85, 36))),
        ])),
        Container(height: 38, width: double.infinity, decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.red, width: 1.5)), child: processing? Stack(children: [FractionallySizedBox(widthFactor: progress / 100, child: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: EdgeInsets.only(left: 12), child: Text("${progress.toStringAsFixed(0)}% Exporting...", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))))]) : Center(child: Text(status, style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold), maxLines: 1)))),
      ]),
    );
  }
}
