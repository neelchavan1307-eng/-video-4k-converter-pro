import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MasterEditor(), theme: ThemeData.dark()));

class MasterEditor extends StatefulWidget { @override _MasterEditorState createState() => _MasterEditorState(); }

class _MasterEditorState extends State<MasterEditor> {
  String? videoPath;
  VideoPlayerController? vc;
  bool processing = false, blurBg = false, stabilize = false, denoise = false, autoHDR = false;
  double progress = 0, speed = 1.0;
  List<String> selected = [];
  String status = "Video निवडा - AI + 90 Filters Ready";
  String aiReason = "AI: Video टाकल्यावर Analysis करून Best Combo सांगेल!";
  List<String> aiList = [];

  final Map<String, Map<String,String>> filters = {
    "f01_normal": {"name": "Normal", "cmd": "", "c": "normal"},
    "f02_bw": {"name": "B&W", "cmd": "hue=s=0", "c": "bw"},
    "f03_sepia": {"name": "Sepia", "cmd": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", "c": "sepia"},
    "f05_warm": {"name": "Warm Birthday", "cmd": "eq=brightness=0.06:saturation=1.35:gamma_r=1.12", "c": "warm"},
    "f07_bright": {"name": "Bright", "cmd": "eq=brightness=0.25:contrast=1.25", "c": "bright"},
    "f08_vivid": {"name": "Vivid", "cmd": "eq=saturation=2.2:contrast=1.3", "c": "vivid"},
    "f10_cinematic": {"name": "Cinematic", "cmd": "eq=contrast=1.2:saturation=1.25,unsharp=3:3:0.5", "c": "cinematic"},
    "f12_hdr": {"name": "HDR 4K", "cmd": "eq=contrast=1.5:saturation=1.45,unsharp=5:5:0.8", "c": "vivid"},
    "f15_dreamy": {"name": "Dreamy Glow", "cmd": "gblur=sigma=0.8,eq=brightness=0.15:saturation=1.3", "c": "bright"},
    "f25_4kultra": {"name": "4K Ultra", "cmd": "scale=3840:2160:flags=lanczos", "c": "normal"},
    "f26_sharpen": {"name": "Sharpen", "cmd": "unsharp=5:5:1.0", "c": "normal"},
    "f28_night": {"name": "Night Boost", "cmd": "eq=brightness=0.35:contrast=1.25", "c": "bright"},
    // ADVANCE FEATURES - माझे Add केलेले
    "f73_love": {"name": "Love Glow", "cmd": "eq=brightness=0.15:saturation=1.6:gamma_r=1.2,gblur=sigma=0.6", "c": "warm"},
    "f74_rose": {"name": "Rose Pink", "cmd": "colorbalance=rs=0.4:bs=0.2,eq=saturation=1.5", "c": "warm"},
    "f75_heart": {"name": "Heart Bokeh", "cmd": "gblur=sigma=2,eq=brightness=0.2:saturation=1.4", "c": "bright"},
    "f76_prem": {"name": "Prem Special", "cmd": "colorchannelmixer=1:.2:.3:0:.1:.9:.2:0:.2:.1:1,eq=saturation=1.6", "c": "vivid"},
    "f77_roadlove": {"name": "Road Love", "cmd": "eq=contrast=1.3:saturation=1.5,vignette=PI/3", "c": "cinematic"},
    "f78_aiuhd": {"name": "AI UHD Pro", "cmd": "scale=3840:2160:flags=lanczos,eq=contrast=1.2:saturation=1.3,unsharp=5:5:1", "c": "vivid"},
    "f79_stable": {"name": "Stabilize", "cmd": "deshake", "c": "normal"},
    "f80_magic": {"name": "Magic Portrait", "cmd": "eq=brightness=0.08:saturation=1.2,unsharp=3:3:0.6,gblur=sigma=0.5", "c": "bright"},
  };
  List<String> get keys {
    while(filters.length < 90){
      int i = filters.length+1;
      filters["f$i"] = {"name": "Pro $i", "cmd": "eq=saturation=${1.2 + (i%5)*0.2}", "c": "normal"};
    }
    return filters.keys.toList();
  }

  ColorFilter getPreview(){
    if(selected.isEmpty) return ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    String c = filters[selected.last]!['c']!;
    if(c=="bw") return ColorFilter.matrix([0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0]);
    if(c=="warm") return ColorFilter.mode(Colors.orange.withOpacity(0.25), BlendMode.overlay);
    if(c=="vivid") return ColorFilter.matrix([1.35,0,0,0,0, 0,1.35,0,0,0, 0,0,1.35,0,0, 0,0,0,1,0]);
    if(c=="bright") return ColorFilter.mode(Colors.white.withOpacity(0.20), BlendMode.lighten);
    return ColorFilter.mode(Colors.transparent, BlendMode.multiply);
  }

  Future<void> analyzeAI(String path) async {
    var infoS = await FFprobeKit.getMediaInformation(path);
    var info = infoS.getMediaInformation();
    double dur = double.tryParse(info?.getDuration()??"0")??0;
    int w = info?.getStreams().first.getWidth()??0;
    String name = path.toLowerCase();
    if(name.contains("birthday") || dur < 15){
      aiList = ["f05_warm", "f15_dreamy", "f78_aiuhd"];
      aiReason = "AI: Birthday ${dur.toInt()}s, ${w}p - Warm Birthday + Dreamy + AI UHD Pro - Best! माझं Advance Feature Auto HDR पण लावलंय!";
      selected = ["f05_warm", "f15_dreamy"]; autoHDR = true;
    } else if(name.contains("love") || name.contains("prem")){
      aiList = ["f73_love", "f74_rose", "f75_heart"];
      aiReason = "AI: Love/Prem Video 💖 Detect - Love Glow + Rose Pink + Heart Bokeh - रस्त्यामधलं प्रेम Effect + Magic Portrait!";
      selected = ["f73_love", "f74_rose"];
    } else if(w < 1280){
      aiList = ["f78_aiuhd", "f26_sharpen", "f12_hdr"];
      aiReason = "AI: Low Quality ${w}p - AI UHD Pro + Sharpen + HDR - 4K Proper Convert + Stabilize Auto ON!";
      selected = ["f78_aiuhd", "f26_sharpen"]; stabilize = true; denoise = true;
    } else {
      aiList = ["f10_cinematic", "f08_vivid", "f78_aiuhd"];
      aiReason = "AI: Daylight ${w}p - Cinematic + Vivid + AI UHD Pro - माझं Advance Magic Portrait पण Try कर!";
      selected = ["f10_cinematic"];
    }
    setState((){});
  }

  Future pickVideo() async {
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if(r==null) return;
    videoPath = r.files.single.path!;
    vc?.dispose();
    vc = VideoPlayerController.file(File(videoPath!));
    await vc!.initialize(); vc!.setLooping(true); vc!.play();
    await analyzeAI(videoPath!);
    setState((){ status = "Ready: ${r.files.single.name}"; });
  }

  void toggle(String k){ setState((){ if(selected.contains(k)) selected.remove(k); else if(selected.length<10) selected.add(k); }); }

  void openFullScreen(){
    if(vc==null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, body: Stack(children: [
      Center(child: AspectRatio(aspectRatio: vc!.value.aspectRatio, child: ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!)))),
      Positioned(top: 40, left: 15, child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: ()=> Navigator.pop(context))),
      Positioned(bottom: 20, left: 15, right: 15, child: ElevatedButton(onPressed: ()=> Navigator.pop(context), child: Text("BACK TO EDITING - ${selected.map((e)=>filters[e]!['name']).join(' + ')}"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF7C4DFF), minimumSize: Size(double.infinity, 50)))),
    ]))));
  }

  Future export() async {
    if(videoPath==null) return;
    setState((){ processing=true; progress=0; });
    var tmp = await getTemporaryDirectory();
    var out = "${tmp.path}/MASTER_${DateTime.now().millisecondsSinceEpoch}.mp4";
    List<String> vf = ["scale=3840:2160:flags=lanczos"];
    if(blurBg) vf.add("gblur=sigma=2");
    if(stabilize) vf.add("deshake");
    if(denoise) vf.add("hqdn3d");
    if(autoHDR) vf.add("eq=contrast=1.3:saturation=1.3");
    for(var k in selected){ if(filters[k]!['cmd']!.isNotEmpty) vf.add(filters[k]!['cmd']!); }
    if(speed!= 1.0) vf.add("setpts=${1/speed}*PTS");
    String cmd = "-i $videoPath -vf ${vf.join(",")} -c:v libx264 -preset ultrafast -crf 18 -c:a aac $out";
    FFmpegKit.executeAsync(cmd, (s) async {
      if(ReturnCode.isSuccess(await s.getReturnCode())){
        var dir = Directory("/storage/emulated/0/Movies/4K Converter");
        if(!await dir.exists()) await dir.create(recursive: true);
        await File(out).copy("${dir.path}/4K_MASTER_${DateTime.now().millisecondsSinceEpoch}.mp4");
        setState((){ processing=false; progress=100; status="✅ 100% Saved to Gallery! 4K + ${selected.length} Filters!"; });
      } else { setState((){ processing=false; status="Failed"; }); }
    }, (l){}, (st){ setState(()=> progress = (st.getTime()/1000).clamp(0,100)); });
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: Colors.black, title: Text("MASTER 4K • ${selected.length} Filters", style: TextStyle(fontSize: 13)), actions: [
        ElevatedButton(onPressed: export, child: Text("Export 4K", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF5AC8FA), foregroundColor: Colors.black, minimumSize: Size(70, 32))),
        SizedBox(width: 8),
      ]),
      body: Column(children: [
        Expanded(flex: 4, child: Container(color: Colors.black, width: double.infinity, child: Stack(children: [
          Center(child: vc!=null && vc!.value.isInitialized? AspectRatio(aspectRatio: vc!.value.aspectRatio, child: ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!))) : GestureDetector(onTap: pickVideo, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 50, color: Colors.white24), ElevatedButton(onPressed: pickVideo, child: Text("PICK VIDEO"))]))),
          Positioned(left: 10, bottom: 10, child: GestureDetector(onTap: openFullScreen, child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white, width: 1.5)), child: Icon(Icons.fullscreen, size: 18, color: Colors.white))))),
          Positioned(right: 10, top: 10, child: Column(children: [
            Switch(value: stabilize, onChanged: (v)=> setState(()=> stabilize=v)), Text("Stabilize", style: TextStyle(fontSize: 7)),
            Switch(value: blurBg, onChanged: (v)=> setState(()=> blurBg=v)), Text("Blur BG", style: TextStyle(fontSize: 7)),
            Switch(value: autoHDR, onChanged: (v)=> setState(()=> autoHDR=v)), Text("AI HDR", style: TextStyle(fontSize: 7)),
          ])),
        ]))),
        Container(height: 135, color: Color(0xFF151515), padding: EdgeInsets.all(6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("🟧 FILTERS - 90 Filters Right to Left Swipe (Tap to Apply Live) - ${selected.length}/10", style: TextStyle(fontSize: 8, color: Colors.orange)),
          SizedBox(height: 4),
          Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: Wrap(direction: Axis.vertical, spacing: 6, runSpacing: 6, children: keys.map((k){
            bool sel = selected.contains(k);
            return GestureDetector(onTap: ()=> toggle(k), child: Container(width: 64, height: 36, decoration: BoxDecoration(color: sel? Colors.orange: Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(6), border: Border.all(color: sel? Colors.white: Colors.transparent, width: sel?1.5:0)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(sel? Icons.check_circle: Icons.filter_alt, size: 11, color: sel? Colors.black: Colors.white60), Text(filters[k]!['name']!, style: TextStyle(fontSize: 6, color: sel? Colors.black: Colors.white), maxLines: 1)])));
          }).toList()))),
        ])),
        Container(width: double.infinity, padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF0F2810), border: Border.all(color: Colors.green, width: 1)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("🟩 AI SUGGESTION - Video Check करून Proper Filter", style: TextStyle(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          SizedBox(height: 3),
          Text(aiReason, style: TextStyle(fontSize: 9, color: Colors.white70)),
          SizedBox(height: 5),
          Wrap(spacing: 6, children: aiList.map((k)=> ActionChip(avatar: Icon(Icons.auto_awesome, size: 10, color: Colors.green), label: Text(filters[k]!['name']!, style: TextStyle(fontSize: 8)), backgroundColor: selected.contains(k)? Colors.green: Colors.green.withOpacity(0.2), onPressed: ()=> toggle(k))).toList()),
        ])),
        Container(height: 32, width: double.infinity, decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.red, width: 1.5), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 10)]), child: processing? Stack(children: [FractionallySizedBox(widthFactor: progress/100, child: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: EdgeInsets.only(left: 8), child: Text("${progress.toStringAsFixed(0)}% - 4K Converting + Saving to Gallery...", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))))]) : Center(child: Text(status, style: TextStyle(fontSize: 10, color: Colors.white70)))),
        if(selected.isNotEmpty) Container(height: 28, color: Colors.black, child: ListView(scrollDirection: Axis.horizontal, reverse: true, children: selected.map((k)=> Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Chip(label: Text(filters[k]!['name']!, style: TextStyle(fontSize: 7)), backgroundColor: Colors.orange, visualDensity: VisualDensity.compact, deleteIcon: Icon(Icons.close, size: 10), onDeleted: ()=> toggle(k)))).toList())),
      ]),
    );
  }
}
