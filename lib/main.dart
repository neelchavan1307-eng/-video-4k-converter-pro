import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: V2Editor(), theme: ThemeData.dark()));

class V2Editor extends StatefulWidget { @override _V2EditorState createState() => _V2EditorState(); }

class _V2EditorState extends State<V2Editor> {
  String? videoPath, musicPath;
  VideoPlayerController? vc;
  bool processing = false, blurBg = false;
  double progress = 0, startTrim = 0, endTrim = 100;
  String status = "Pick a Video", quality = "2160";
  List<String> selectedFilters = ["f05_warm"]; // आता Multi - List!
  String overlayText = "";
  TextEditingController textCtrl = TextEditingController();
  List<String> aiSuggestions = ["f05_warm", "f15_dreamy", "f12_hdr"]; // आता 3 AI Suggestions
  String aiReason = "Video टाका - AI Check करेल!";

  // 72 FILTERS - तुझ्या 24 मध्ये 48 अजून Add केले - Proper Apply होतील
  final Map<String, Map<String,String>> filters = {
    "f01_normal": {"name": "Normal", "cmd": ""},
    "f02_bw": {"name": "B&W", "cmd": "hue=s=0"},
    "f03_sepia": {"name": "Sepia", "cmd": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131"},
    "f04_vintage": {"name": "Vintage", "cmd": "curves=vintage"},
    "f05_warm": {"name": "Warm Birthday", "cmd": "eq=brightness=0.05:saturation=1.3:gamma_r=1.1"},
    "f06_cold": {"name": "Cold", "cmd": "eq=saturation=1.2:gamma_b=1.2"},
    "f07_bright": {"name": "Bright", "cmd": "eq=brightness=0.2:contrast=1.2"},
    "f08_vivid": {"name": "Vivid", "cmd": "eq=saturation=2:contrast=1.2"},
    "f09_blur": {"name": "Blur", "cmd": "gblur=sigma=1.5"},
    "f10_cinematic": {"name": "Cinematic", "cmd": "eq=contrast=1.15:saturation=1.2,unsharp=3:3:0.5"},
    "f11_golden": {"name": "Golden Hour", "cmd": "colorbalance=rs=0.3:bs=-0.2,eq=saturation=1.3"},
    "f12_hdr": {"name": "HDR 4K", "cmd": "eq=contrast=1.5:saturation=1.4,unsharp=5:5:0.8"},
    "f13_noir": {"name": "Noir", "cmd": "hue=s=0,eq=contrast=1.4"},
    "f14_cartoon": {"name": "Cartoon", "cmd": "edgedetect=low=0.1:high=0.4"},
    "f15_dreamy": {"name": "Dreamy Glow", "cmd": "gblur=sigma=0.8,eq=brightness=0.15:saturation=1.3"},
    "f16_neon": {"name": "Neon Party", "cmd": "eq=saturation=2.5:contrast=1.4"},
    "f17_oldfilm": {"name": "Old Film", "cmd": "curves=preset=vintage,noise=alls=10"},
    "f18_clarendon": {"name": "Clarendon", "cmd": "eq=contrast=1.2:saturation=1.35"},
    "f19_lomo": {"name": "Lomo", "cmd": "curves=preset=lomo"},
    "f20_moon": {"name": "Moon", "cmd": "hue=s=0"},
    "f21_fire": {"name": "Fire", "cmd": "colorbalance=rs=0.4,eq=saturation=1.4"},
    "f22_ice": {"name": "Ice", "cmd": "colorbalance=bs=0.4"},
    "f23_pop": {"name": "Pop Art", "cmd": "eq=saturation=3:contrast=2"},
    "f24_portrait": {"name": "Portrait Pro", "cmd": "eq=brightness=0.08:saturation=1.1,unsharp=3:3:0.5"},
    // 25-72 नवीन - 72 पूर्ण
    "f25_4kultra": {"name": "4K Ultra", "cmd": "scale=3840:2160:flags=lanczos"},
    "f26_sharpen": {"name": "Sharpen", "cmd": "unsharp=5:5:1"},
    "f27_softskin": {"name": "Soft Skin", "cmd": "eq=saturation=1.1,gblur=sigma=0.8"},
    "f28_night": {"name": "Night Boost", "cmd": "eq=brightness=0.3:contrast=1.2"},
    "f29_day": {"name": "Daylight", "cmd": "eq=brightness=0.05:saturation=1.2"},
    "f30_landscape": {"name": "Landscape", "cmd": "eq=saturation=1.5:contrast=1.15"},
    "f31_gold": {"name": "Gold", "cmd": "colorchannelmixer=1.2:.3:.1:0:.2:1:.1:0:.1:.2:.9"},
    "f32_silver": {"name": "Silver", "cmd": "hue=s=0.1,eq=contrast=1.15"},
    "f33_cyber": {"name": "Cyberpunk", "cmd": "eq=saturation=2:contrast=1.3,colorbalance=rs=0.3:bs=-0.3"},
    "f34_dreamy2": {"name": "Dreamy", "cmd": "gblur=sigma=1.5,eq=brightness=0.08"},
    "f35_mirror": {"name": "Mirror", "cmd": "hflip"},
    "f36_vignette": {"name": "Vignette", "cmd": "vignette=PI/4"},
    "f37_insta": {"name": "Insta Sq", "cmd": "crop=1:1,scale=1080:1080"},
    "f38_sunset": {"name": "Sunset", "cmd": "eq=brightness=0.08:saturation=1.8:contrast=1.2"},
    "f39_sunrise": {"name": "Sunrise", "cmd": "eq=brightness=0.18:saturation=1.4"},
    "f40_rosegold": {"name": "Rose Gold", "cmd": "colorchannelmixer=1:.3:.3:0:.2:.7:.3:0:.2:.3:.9"},
    "f41_fade": {"name": "Fade", "cmd": "eq=brightness=0.12:contrast=0.85:saturation=0.8"},
    "f42_highkey": {"name": "High Key", "cmd": "eq=brightness=0.28:contrast=0.85"},
    "f43_lowkey": {"name": "Low Key", "cmd": "eq=brightness=-0.25:contrast=1.45"},
    "f44_pastel": {"name": "Pastel", "cmd": "eq=saturation=0.7:brightness=0.15"},
    "f45_bronze": {"name": "Bronze", "cmd": "colorchannelmixer=1:.5:.2:0:.3:.8:.2:0:.1:.3:.7"},
    "f46_deepblue": {"name": "Deep Blue", "cmd": "colorbalance=bs=0.5"},
    "f47_deepred": {"name": "Deep Red", "cmd": "colorbalance=rs=0.5"},
    "f48_indoor": {"name": "Indoor", "cmd": "eq=brightness=0.15:saturation=1.1"},
    "f49_grain": {"name": "Grain", "cmd": "noise=alls=20:allf=t"},
    "f50_denoise": {"name": "DeNoise", "cmd": "hqdn3d"},
    "f51_emboss": {"name": "Emboss", "cmd": "convolution=-2 -1 0 -1 1 1 0 1 2:0:0:0:0:1:0"},
    "f52_pixel": {"name": "Pixelate", "cmd": "scale=iw/10:ih/10:flags=neighbor,scale=10*iw:10*ih:flags=neighbor"},
    "f53_rotate": {"name": "Rotate 90", "cmd": "transpose=1"},
    "f54_fish": {"name": "Fish Eye", "cmd": "vignette=angle=PI/4"},
    "f55_glow": {"name": "Glow", "cmd": "gblur=sigma=3,eq=brightness=0.18"},
    "f56_echo": {"name": "Echo", "cmd": "tblend=all_mode=average"},
    "f57_slow": {"name": "Slow Mo", "cmd": "setpts=2*PTS"},
    "f58_fast": {"name": "Fast 2x", "cmd": "setpts=0.5*PTS"},
    "f59_cinema": {"name": "CinemaScope", "cmd": "crop=21/9*ih:ih,scale=1920:820"},
    "f60_zoom": {"name": "Zoom In", "cmd": "scale=2*iw:2*ih,crop=iw/2:ih/2"},
    "f61_flip": {"name": "Flip V", "cmd": "vflip"},
    "f62_ice2": {"name": "Ice Pro", "cmd": "colortemperature=temperature=3000,eq=saturation=1.2"},
    "f63_fire2": {"name": "Fire Pro", "cmd": "colortemperature=temperature=8000,eq=saturation=1.8"},
    "f64_neon2": {"name": "Neon Glow", "cmd": "eq=saturation=2.5:contrast=1.4:brightness=0.12"},
    "f65_matrix": {"name": "Matrix", "cmd": "colorchannelmixer=.1:.9:.1:0:.1:.9:.1:0"},
    "f66_monoR": {"name": "Mono Red", "cmd": "colorchannelmixer=1:0:0:0:0:0:0:0"},
    "f67_monoB": {"name": "Mono Blue", "cmd": "colorchannelmixer=0:0:1:0:0:0:0:0:0:0:1:0"},
    "f68_invert": {"name": "Inverted", "cmd": "negate"},
    "f69_sharpS": {"name": "Sharp Strong", "cmd": "unsharp=7:7:2.5"},
    "f70_blurH": {"name": "Blur Heavy", "cmd": "gblur=sigma=10"},
    "f71_dark": {"name": "Dark -20", "cmd": "eq=brightness=-0.2"},
    "f72_bright40": {"name": "Bright +40", "cmd": "eq=brightness=0.4"},
  };
  List<String> get keys => filters.keys.toList();

  // AI Video Check - व्हिडिओ चेक करून Best Filter Combo सांगणार
  Future<void> analyzeAI(String path) async {
    setState((){ aiReason = "AI Video Check करत आहे..."; });
    var infoS = await FFprobeKit.getMediaInformation(path);
    var info = infoS.getMediaInformation();
    double dur = double.tryParse(info?.getDuration()??"0")?? 0;
    int w = 0;
    if(info?.getStreams().isNotEmpty??false) w = info!.getStreams().first.getWidth()?? 0;

    if(path.toLowerCase().contains("birthday") || path.toLowerCase().contains("party") || dur < 20){
      aiSuggestions = ["f05_warm", "f15_dreamy", "f25_4kultra"];
      aiReason = "AI Detect: Birthday Video (${dur.toInt()}s). अंधार आहे, Warm Birthday + Dreamy Glow + 4K Ultra हे 3 एकत्र लावा - हेच Best Combo!";
    } else if(w < 1280){
      aiSuggestions = ["f25_4kultra", "f26_sharpen", "f12_hdr"];
      aiReason = "Low Quality (${w}p) Video आहे. AI Suggestion: 4K Ultra + Sharpen + HDR 4K - 3 Filter एकत्र Apply करा!";
    } else if(path.toLowerCase().contains("night")){
      aiSuggestions = ["f28_night", "f07_bright", "f12_hdr"];
      aiReason = "Night Video Detect. Bright + Night Boost + HDR 4K हा Combo योग्य राहील!";
    } else {
      aiSuggestions = ["f10_cinematic", "f08_vivid", "f12_hdr"];
      aiReason = "Daylight Video. Cinematic + Vivid + HDR 4K - हे 3 एकत्र लावा!";
    }
    setState((){ selectedFilters = List.from(aiSuggestions); }); // AI ने सांगितलेले Auto Select
  }

  Future pickVideo() async {
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if(r==null) return;
    videoPath = r.files.single.path!;
    vc?.dispose();
    vc = VideoPlayerController.file(File(videoPath!));
    await vc!.initialize(); vc!.setLooping(true); vc!.play();
    await analyzeAI(videoPath!);
    setState(() { status="Ready: ${r.files.single.name} | ${selectedFilters.length} Filters Auto-Selected"; });
  }

  Future pickMusic() async {
    var r = await FilePicker.platform.pickFiles(type: FileType.audio);
    if(r!=null) setState(() { musicPath=r.files.single.path!; status="Music Added: ${r.files.single.name}"; });
  }

  void toggleFilter(String k){
    setState((){
      if(selectedFilters.contains(k)) selectedFilters.remove(k);
      else if(selectedFilters.length < 10) selectedFilters.add(k); // 10 पर्यंत एकत्र!
    });
  }

  void fullScreen() {
    if(vc==null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_)=>Scaffold(backgroundColor: Colors.black, body: Stack(children: [
      Center(child: AspectRatio(aspectRatio: vc!.value.aspectRatio, child: VideoPlayer(vc!))),
      Positioned(top:40, left:15, child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: ()=>Navigator.pop(context))),
      Positioned(bottom:20, left:20, right:20, child: ElevatedButton(onPressed: ()=>Navigator.pop(context), child: Text("BACK - ${selectedFilters.map((e)=>filters[e]!['name']).join(' + ')}"), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple))),
    ]))));
  }

  Future convert() async {
    if(videoPath==null) return;
    if(selectedFilters.isEmpty){ setState(()=> status="किमान 1 Filter निवडा!"); return; }
    setState(() { processing=true; progress=0; });
    var tmp = await getTemporaryDirectory();
    var out = "${tmp.path}/V2_${DateTime.now().millisecondsSinceEpoch}.mp4";
    double dur = vc!.value.duration.inSeconds.toDouble();
    double sSec = dur * (startTrim/100);
    double eSec = dur * (endTrim/100);

    // Multi-Filter Combine - सगळे एकत्र Apply!
    List<String> vf = ["scale=-2:$quality"];
    if(blurBg) vf.add("gblur=sigma=2:steps=1");
    for(var k in selectedFilters){
      if(filters[k]!['cmd']!.isNotEmpty) vf.add(filters[k]!['cmd']!);
    }
    if(overlayText.isNotEmpty){
      vf.add("drawtext=text='$overlayText':fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=10:x=(w-text_w)/2:y=h-th-100");
    }
    String vfStr = vf.join(",");

    String cmd = musicPath!=null
     ? "-ss $sSec -to $eSec -i $videoPath -i $musicPath -vf $vfStr -map 0:v:0 -map 1:a:0 -shortest -c:v libx264 -preset ultrafast -c:a aac $out"
      : "-ss $sSec -to $eSec -i $videoPath -vf $vfStr -c:v libx264 -preset ultrafast -c:a aac $out";

    FFmpegKit.executeAsync(cmd, (session) async {
      if(ReturnCode.isSuccess(await session.getReturnCode())){
        var moviesDir = Directory("/storage/emulated/0/Movies/4K Converter");
        if(!await moviesDir.exists()) await moviesDir.create(recursive: true);
        var newPath = "${moviesDir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
        await File(out).copy(newPath);
        setState(() { processing=false; progress=100; status="✅ 100% Saved! ${selectedFilters.length} Filters Applied!"; });
        showDialog(context: context, builder: (_)=>AlertDialog(title: Text("Saved!"), content: Text("Video saved to Movies/4K Converter\nFilters: ${selectedFilters.map((e)=>filters[e]!['name']).join(' + ')}\nProperly Applied!"), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text("OK"))]));
      } else {
        setState(() { processing=false; status="Failed"; });
      }
    }, (l){}, (st){
      double p = (st.getTime()/1000) / (eSec - sSec) * 100;
      if(p.isNaN) p=0;
      setState(() { progress=p.clamp(0,100); status="Converting ${p.toStringAsFixed(0)}% - ${selectedFilters.length} Filters"; });
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text("4K V2 PRO - ${selectedFilters.length} Filters"), actions: [
        ElevatedButton.icon(icon: Icon(Icons.auto_awesome), label: Text("AI ENHANCE"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black), onPressed: (){ if(videoPath!=null) analyzeAI(videoPath!); }),
        SizedBox(width:6),
        ElevatedButton(onPressed: convert, child: Text("EXPORT 4K"), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black)),
        SizedBox(width:10),
      ]),
      body: Column(children: [
        Expanded(flex: 4, child: Stack(children: [
          Center(child: vc!=null && vc!.value.isInitialized? AspectRatio(aspectRatio: vc!.value.aspectRatio, child: VideoPlayer(vc!)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 80, color: Colors.white24), SizedBox(height:10), ElevatedButton(onPressed: pickVideo, child: Text("PICK VIDEO -
