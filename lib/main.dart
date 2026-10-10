import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: ProMaxApp(), theme: ThemeData.dark()));
class ProMaxApp extends StatefulWidget { @override State<ProMaxApp> createState() => _ProMaxAppState(); }
class _ProMaxAppState extends State<ProMaxApp> {
  String? videoPath, musicPath; VideoPlayerController? vc;
  bool processing=false, stabilize=false, denoise=false, hdr=false, captionOn=false, beat=false, enhance=true;
  double progress=0; List<String> sel=[]; String status="PRO MAX Ready - 52 Filters + AI";
  String aiText="Video टाका - AI Auto Analyze करेल!"; List<String> aiSug=[];
  String cap="Happy Birthday Prem!"; TextEditingController capCtrl=TextEditingController(text:"Happy Birthday Prem!"); String meta="";
  final Map<String, Map<String, String>> filters = {
    "f01": {"name": "Normal", "cmd": "", "c": "n"},
    "f02": {"name": "B&W", "cmd": "hue=s=0", "c": "b"},
    "f03": {"name": "Sepia", "cmd": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", "c": "s"},
    "f04": {"name": "Warm BDay", "cmd": "eq=brightness=0.06:saturation=1.35", "c": "w"},
    "f05": {"name": "Bright", "cmd": "eq=brightness=0.25:contrast=1.25", "c": "b2"},
    "f06": {"name": "Vivid", "cmd": "eq=saturation=2.2:contrast=1.3", "c": "v"},
    "f07": {"name": "Cinematic", "cmd": "eq=contrast=1.2:saturation=1.25", "c": "c"},
    "f08": {"name": "HDR 4K", "cmd": "eq=contrast=1.5:saturation=1.45", "c": "v"},
    "f09": {"name": "Noir", "cmd": "hue=s=0,eq=contrast=1.5", "c": "b"},
    "f10": {"name": "Dreamy", "cmd": "eq=brightness=0.15:saturation=1.3", "c": "b2"},
    "f11": {"name": "Neon", "cmd": "eq=saturation=2.5:contrast=1.4", "c": "v"},
    "f12": {"name": "Fire", "cmd": "colorbalance=rs=0.4", "c": "w"},
    "f13": {"name": "Ice", "cmd": "colorbalance=bs=0.4", "c": "w"},
    "f14": {"name": "4K Ultra", "cmd": "scale=3840:2160:flags=lanczos", "c": "n"},
    "f15": {"name": "Sharpen", "cmd": "unsharp=7:7:1.5", "c": "n"},
    "f16": {"name": "Night AI", "cmd": "eq=brightness=0.35:contrast=1.25", "c": "b2"},
    "f17": {"name": "Portrait", "cmd": "eq=brightness=0.08:saturation=1.15", "c": "b2"},
    "f18": {"name": "Vignette", "cmd": "vignette=PI/4", "c": "c"},
    "f19": {"name": "Sunset", "cmd": "eq=brightness=0.08:saturation=1.8", "c": "w"},
    "f20": {"name": "Gold", "cmd": "colorchannelmixer=1.2:.4:.2:0", "c": "w"},
    "f21": {"name": "DeNoise", "cmd": "hqdn3d", "c": "n"},
    "f22": {"name": "Rotate", "cmd": "transpose=1", "c": "n"},
    "f23": {"name": "SlowMo", "cmd": "setpts=2*PTS", "c": "n"},
    "f24": {"name": "Fast2x", "cmd": "setpts=0.5*PTS", "c": "n"},
    "f25": {"name": "Ice Max", "cmd": "colortemperature=temperature=2500", "c": "c"},
    "f26": {"name": "Fire Max", "cmd": "colortemperature=temperature=9000", "c": "w"},
    "f27": {"name": "Neon Max", "cmd": "eq=saturation=2.8:contrast=1.5", "c": "v"},
    "f28": {"name": "Sharp Max", "cmd": "unsharp=9:9:2.5", "c": "n"},
    "f29": {"name": "Blur Heavy", "cmd": "gblur=sigma=12", "c": "n"},
    "f30": {"name": "Love Glow", "cmd": "eq=brightness=0.15:saturation=1.8", "c": "w"},
    "f31": {"name": "Rose Pink", "cmd": "colorbalance=rs=0.5:bs=0.3", "c": "w"},
    "f32": {"name": "Prem Special", "cmd": "colorchannelmixer=1:.2:.4:0", "c": "v"},
    "f33": {"name": "Road Love", "cmd": "eq=contrast=1.3:saturation=1.6", "c": "c"},
    "f34": {"name": "AI UHD", "cmd": "scale=3840:2160:flags=lanczos,eq=contrast=1.25:saturation=1.35", "c": "v"},
    "f35": {"name": "HDR Max", "cmd": "eq=contrast=1.45:saturation=1.6", "c": "v"},
    "f36": {"name": "AI Face", "cmd": "eq=brightness=0.1:saturation=1.3", "c": "b2"},
    "f37": {"name": "Bokeh", "cmd": "gblur=sigma=5", "c": "b2"},
    "f38": {"name": "Wedding", "cmd": "eq=brightness=0.12:saturation=1.35", "c": "w"},
    "f39": {"name": "Haldi", "cmd": "colorbalance=rs=0.3:gs=0.2", "c": "w"},
    "f40": {"name": "Sangeet", "cmd": "eq=saturation=2.2:contrast=1.3", "c": "v"},
    "f41": {"name": "Reel Viral", "cmd": "eq=saturation=1.6:contrast=1.25", "c": "v"},
    "f42": {"name": "Insta Viral", "cmd": "eq=saturation=1.8:contrast=1.3", "c": "v"},
    "f43": {"name": "YT Shorts", "cmd": "scale=1080:1920:flags=lanczos", "c": "v"},
    "f44": {"name": "BDay Blast", "cmd": "eq=brightness=0.1:saturation=1.8", "c": "w"},
    "f45": {"name": "Model Pro", "cmd": "eq=brightness=0.08:saturation=1.3", "c": "b2"},
    "f46": {"name": "Green Screen", "cmd": "chromakey=0x00FF00:0.3:0.2", "c": "n"},
    "f47": {"name": "Reverse", "cmd": "reverse", "c": "n"},
    "f48": {"name": "Mirror", "cmd": "hflip,vflip", "c": "n"},
    "f49": {"name": "Punjabi", "cmd": "eq=saturation=2:contrast=1.3", "c": "v"},
    "f50": {"name": "Marathi Lavni", "cmd": "colorbalance=rs=0.3:gs=0.1", "c": "w"},
    "f51": {"name": "Bhojpuri", "cmd": "eq=saturation=1.9:contrast=1.35", "c": "v"},
    "f52": {"name": "GOD MAX", "cmd": "scale=3840:2160:flags=lanczos,eq=contrast=1.35:saturation=1.5:brightness=0.05", "c": "v"},
  };
  List<String> get keys => filters.keys.toList();
  ColorFilter getPreview() {
    if (sel.isEmpty) return ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    String c = filters[sel.last]!["c"]!; if (c=="b") return ColorFilter.matrix([0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0]);
    if (c=="w") return ColorFilter.mode(Colors.orange.withOpacity(0.25), BlendMode.overlay);
    if (c=="v") return ColorFilter.matrix([1.3,0,0,0,0, 0,1.3,0,0,0, 0,0,1.3,0,0, 0,0,0,1,0]);
    return ColorFilter.mode(Colors.white.withOpacity(0.2), BlendMode.lighten);
  }
  Future<void> analyze(String path) async {
    var s = await FFprobeKit.getMediaInformation(path); var info = s.getMediaInformation(); if (info==null) return;
    double d = double.tryParse(info.getDuration()??"0")??0; int w = info.getStreams().isNotEmpty? (info.getStreams().first.getWidth()??0):0; int h = info.getStreams().isNotEmpty? (info.getStreams().first.getHeight()??0):0;
    String low=path.toLowerCase(); meta="${w}x${h} | ${d.toStringAsFixed(1)}s";
    if (low.contains("birthday")) { aiSug=["f04","f10","f44","f34"]; aiText="TRUE AI: Birthday $meta -> BEST!"; sel=["f04","f10","f34"]; hdr=true; }
    else if (low.contains("prem")||low.contains("love")||low.contains("wedding")) { aiSug=["f30","f32","f38","f33"]; aiText="TRUE AI: Love $meta -> Trending!"; sel=["f32","f30","f38"]; hdr=true; }
    else if (w<1280) { aiSug=["f34","f15","f21","f35"]; aiText="TRUE AI: Low Quality ${w}p -> 4K!"; sel=["f34","f15","f21"]; stabilize=true; denoise=true; hdr=true; }
    else { aiSug=["f52","f07","f34","f18"]; aiText="TRUE AI: Daylight $meta -> GOD MAX Cinema!"; sel=["f52"]; }
    setState(() {});
  }
  Future pickVideo() async { var r=await FilePicker.platform.pickFiles(type: FileType.video); if(r==null) return; videoPath=r.files.single.path!; vc?.dispose(); vc=VideoPlayerController.file(File(videoPath!)); await vc!.initialize(); vc!.setLooping(true); vc!.play(); await analyze(videoPath!); setState((){ status="Ready: ${r.files.single.name}"; }); }
  Future pickMusic() async { var r=await FilePicker.platform.pickFiles(type: FileType.audio); if(r==null) return; musicPath=r.files.single.path!; setState((){ status="Music Added"; beat=true; }); }
  void toggle(String k){ setState((){ if(sel.contains(k)) sel.remove(k); else if(sel.length<10) sel.add(k); }); }
  Future export() async {
    if(videoPath==null) return; setState((){ processing=true; progress=0; });
    var tmp=await getTemporaryDirectory(); var out="${tmp.path}/promax_${DateTime.now().millisecondsSinceEpoch}.mp4";
    List<String> vf=[]; vf.add("scale=3840:2160:flags=lanczos");
    if(stabilize) vf.add("deshake=rx=20:ry=20"); if(denoise) vf.add("hqdn3d=4:4:6:6"); if(hdr) vf.add("eq=contrast=1.35:saturation=1.45");
    for(var k in sel){ var c=filters[k]!["cmd"]!; if(c.isNotEmpty) vf.add(c); }
    if(captionOn) vf.add("drawtext=text='$cap':fontcolor=white:fontsize=60:borderw=3:bordercolor=black:x=(w-text_w)/2:y=h-th-200");
    String cmd; if(musicPath!=null){ cmd="-i $videoPath -i $musicPath -vf ${vf.join(",")} -map 0:v:0 -map 1:a:0 -shortest -c:v libx264 -preset ultrafast -crf 18 -c:a aac $out"; } else { cmd="-i $videoPath -vf ${vf.join(",")} -c:v libx264 -preset ultrafast -crf 18 -c:a aac $out"; }
    FFmpegKit.executeAsync(cmd, (s) async {
      if(ReturnCode.isSuccess(await s.getReturnCode())){ try{ var dir=Directory("/storage/emulated/0/Movies/4K Converter"); if(!await dir.exists()) await dir.create(recursive:true); await File(out).copy("${dir.path}/PROMAX_${DateTime.now().millisecondsSinceEpoch}.mp4"); }catch(e){} setState((){ processing=false; progress=100; status="Saved! Gallery Check Kara"; }); }
      else { setState((){ processing=false; status="Failed - Try less filters"; }); }
    }, (log){}, (st){ setState((){ progress=(st.getTime()/1000).clamp(0,99).toDouble(); }); });
  }
  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: Colors.black, title: Text("PRO MAX GOD - ${sel.length}/10 - $meta", style: TextStyle(fontSize: 12)), actions: [ElevatedButton(onPressed: export, child: Text("Export 4K", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFD700), foregroundColor: Colors.black)), SizedBox(width: 8)]),
      body: Column(children: [
        Container(height: MediaQuery.of(context).size.height*0.48, color: Colors.black, width: double.infinity, child: Stack(children: [
          Center(child: vc!=null && vc!.value.isInitialized? FittedBox(fit: BoxFit.contain, child: SizedBox(width: vc!.value.size.width, height: vc!.value.size.height, child: ColorFiltered(colorFilter: getPreview(), child: VideoPlayer(vc!)))) : GestureDetector(onTap: pickVideo, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 50, color: Colors.white24), SizedBox(height: 8), ElevatedButton(onPressed: pickVideo, child: Text("PICK VIDEO"))]))),
          Positioned(left: 10, bottom: 10, child: GestureDetector(onTap: (){ if(vc!=null){ Navigator.push(context, MaterialPageRoute(builder: (_)=>Scaffold(backgroundColor: Colors.black, body: Center(child: AspectRatio(aspectRatio: vc!.value.aspectRatio, child: VideoPlayer(vc!)))))); } }, child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.fullscreen, size: 18, color: Colors.white)))),
          Positioned(right: 6, top: 6, child: Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)), child: Column(children: [
            Row(children: [Switch(value: enhance, onChanged: (v)=>setState(()=>enhance=v), activeColor: Color(0xFFFFD700)), Text("AI Enhance", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: stabilize, onChanged: (v)=>setState(()=>stabilize=v), activeColor: Colors.orange), Text("Stabilize", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: hdr, onChanged: (v)=>setState(()=>hdr=v), activeColor: Colors.red), Text("HDR", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: denoise, onChanged: (v)=>setState(()=>denoise=v), activeColor: Colors.blue), Text("DeNoise", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: captionOn, onChanged: (v)=>setState(()=>captionOn=v), activeColor: Colors.green), Text("Caption", style: TextStyle(fontSize: 9))]),
            Row(children: [Switch(value: beat, onChanged: (v)=>setState(()=>beat=v), activeColor: Colors.pink), Text("Beat", style: TextStyle(fontSize: 9))]),
          ]))),
        ])),
        Container(height: 160, color: Color(0xFF151515), padding: EdgeInsets.all(6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("FILTERS - 52 Filters - ${sel.length}/10", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: Wrap(direction: Axis.vertical, spacing: 6, runSpacing: 6, children: keys.map((k){
            bool s=sel.contains(k); return GestureDetector(onTap: ()=>toggle(k), child: Container(width: 80, height: 40, decoration: BoxDecoration(color: s? Colors.orange : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8), border: Border.all(color: s? Colors.white : Colors.transparent, width: s?1.5:0)), child: Center(child: Text(filters[k]!["name"]!, style: TextStyle(fontSize: 8, color: s? Colors.black : Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis))));
          }).toList()))),
        ])),
        Container(width: double.infinity, padding: EdgeInsets.all(8), color: Color(0xFF0F2810), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("TRUE AI", style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          Text(aiText, style: TextStyle(fontSize: 10, color: Colors.white70)),
          SizedBox(height: 4),
          Wrap(spacing: 6, children: aiSug.map((k)=>ActionChip(label: Text(filters[k]!["name"]!, style: TextStyle(fontSize: 9)), backgroundColor: sel.contains(k)? Colors.green : Colors.white12, onPressed: ()=>toggle(k))).toList()),
        ])),
        Container(height: 44, color: Colors.black, padding: EdgeInsets.symmetric(horizontal: 6), child: Row(children: [
          Expanded(child: TextField(controller: capCtrl, onChanged: (v)=>cap=v, decoration: InputDecoration(hintText: "Caption - Happy Birthday Prem!", isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)), style: TextStyle(fontSize: 11))),
          SizedBox(width: 6), ElevatedButton(onPressed: pickMusic, child: Text(musicPath==null? "Music" : "Added", style: TextStyle(fontSize: 10)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white12)),
        ])),
        Container(height: 36, width: double.infinity, color: Colors.black, child: processing? LinearProgressIndicator(value: progress/100, backgroundColor: Colors.white12, color: Colors.red) : Center(child: Text(status, style: TextStyle(fontSize: 11, color: Colors.white70)))),
      ]),
    );
  }
}
