import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: V2Editor(), theme: ThemeData.dark()));

class V2Editor extends StatefulWidget {
  @override _V2EditorState createState() => _V2EditorState();
}

class _V2EditorState extends State<V2Editor> {
  String? videoPath, musicPath;
  VideoPlayerController? vc;
  bool processing = false, blurBg = false;
  double progress = 0, startTrim = 0, endTrim = 100;
  String status = "Pick a Video", quality = "2160", filterKey = "f01_normal", overlayText = "";
  TextEditingController textCtrl = TextEditingController();
  String ai1 = "f12_cinematic", ai2 = "f09_vivid";

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
  };
  List<String> get keys => filters.keys.toList();

  Future pickVideo() async {
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if(r==null) return;
    videoPath = r.files.single.path!;
    String name = r.files.single.name.toLowerCase();
    if(name.contains("birthday") || name.contains("party")){
      ai1="f05_warm"; ai2="f15_dreamy"; overlayText="Happy Birthday!";
    } else if(name.contains("night")){
      ai1="f07_bright"; ai2="f12_hdr";
    } else {
      ai1="f10_cinematic"; ai2="f08_vivid";
    }
    textCtrl.text = overlayText;
    vc?.dispose();
    vc = VideoPlayerController.file(File(videoPath!));
    await vc!.initialize(); vc!.setLooping(true); vc!.play();
    setState(() { status="Ready: ${r.files.single.name}"; startTrim=0; endTrim=100; });
  }
  Future pickMusic() async {
    var r = await FilePicker.platform.pickFiles(type: FileType.audio);
    if(r!=null) setState(() { musicPath=r.files.single.path!; status="Music Added: ${r.files.single.name}"; });
  }

  void fullScreen() {
    if(vc==null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_)=>Scaffold(backgroundColor: Colors.black, body: Stack(children: [
      Center(child: AspectRatio(aspectRatio: vc!.value.aspectRatio, child: VideoPlayer(vc!))),
      Positioned(top:40, left:15, child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: ()=>Navigator.pop(context))),
      Positioned(bottom:20, left:20, right:20, child: ElevatedButton(onPressed: ()=>Navigator.pop(context), child: Text("BACK TO EDITING - ${filters[filterKey]!['name']}"), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, minimumSize: Size(double.infinity, 50)))),
    ]))));
  }

  Future convert() async {
    if(videoPath==null) return;
    setState(() { processing=true; progress=0; });
    var tmp = await getTemporaryDirectory();
    var out = "${tmp.path}/V2_${DateTime.now().millisecondsSinceEpoch}.mp4";
    double dur = vc!.value.duration.inSeconds.toDouble();
    double sSec = dur * (startTrim/100);
    double eSec = dur * (endTrim/100);
    List<String> vf = ["scale=-2:$quality"];
    if(blurBg) vf.add("gblur=sigma=2:steps=1");
    if(filters[filterKey]!['cmd']!.isNotEmpty) vf.add(filters[filterKey]!['cmd']!);
    if(overlayText.isNotEmpty){
      vf.add("drawtext=text='$overlayText':fontcolor=white:fontsize=60:box=1:boxcolor=black@0.5:boxborderw=10:x=(w-text_w)/2:y=h-th-100");
    }
    String vfStr = vf.join(",");
    String cmd;
    if(musicPath!=null){
      cmd = "-ss $sSec -to $eSec -i $videoPath -i $musicPath -vf $vfStr -map 0:v:0 -map 1:a:0 -shortest -c:v libx264 -preset ultrafast -c:a aac $out";
    } else {
      cmd = "-ss $sSec -to $eSec -i $videoPath -vf $vfStr -c:v libx264 -preset ultrafast -c:a aac $out";
    }

    FFmpegKit.executeAsync(cmd, (session) async {
      if(ReturnCode.isSuccess(await session.getReturnCode())){
        // EDITED: gal काढून Direct Gallery Save
        var moviesDir = Directory("/storage/emulated/0/Movies/4K Converter");
        if(!await moviesDir.exists()) await moviesDir.create(recursive: true);
        var newPath = "${moviesDir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
        await File(out).copy(newPath);
        setState(() { processing=false; progress=100; status="✅ 100% Saved to Gallery!"; });
        showDialog(context: context, builder: (_)=>AlertDialog(title: Text("Saved!"), content: Text("Video saved to Movies/4K Converter in 4K with ${filters[filterKey]!['name']}"), actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: Text("OK")),
        ]));
      } else {
        setState(() { processing=false; status="Failed"; });
      }
    }, (l){}, (st){
      double p = (st.getTime()/1000) / (eSec - sSec) * 100;
      if(p.isNaN) p=0;
      setState(() { progress=p.clamp(0,100); status="Converting ${p.toStringAsFixed(0)}% - ${filters[filterKey]!['name']}"; });
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text("4K V2 PRO"), actions: [
        ElevatedButton.icon(icon: Icon(Icons.auto_awesome), label: Text("AI ENHANCE"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black), onPressed: (){ setState((){ filterKey="f12_hdr"; quality="2160"; blurBg=false; }); convert(); }),
        SizedBox(width:6),
        ElevatedButton(onPressed: convert, child: Text("EXPORT 4K"), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black)),
        SizedBox(width:10),
      ]),
      body: Column(children: [
        Expanded(flex: 4, child: Stack(children: [
          Center(child: vc!=null && vc!.value.isInitialized? AspectRatio(aspectRatio: vc!.value.aspectRatio, child: VideoPlayer(vc!)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, size: 80, color: Colors.white24), SizedBox(height:10), ElevatedButton(onPressed: pickVideo, child: Text("PICK VIDEO"))])),
          Positioned(left:8, bottom:35, child: GestureDetector(onTap: fullScreen, child: Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white)), child: Icon(Icons.fullscreen, size: 20)))),
          Positioned(bottom:5, left:10, right:10, child: vc!=null? RangeSlider(min:0, max:100, values: RangeValues(startTrim, endTrim), activeColor: Colors.cyanAccent, labels: RangeLabels("${startTrim.toInt()}%", "${endTrim.toInt()}%"), onChanged: (v){ setState((){ startTrim=v.start; endTrim=v.end; }); }) : SizedBox()),
        ])),
        Container(height: 90, color: Color(0xFF111111), child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: keys.length, itemBuilder: (c,i){
          var k = keys[i]; bool sel = k==filterKey;
          return GestureDetector(onTap: ()=>setState(()=>filterKey=k), child: Container(width: 75, margin: EdgeInsets.all(6), decoration: BoxDecoration(color: sel? Colors.deepPurple : Colors.white12, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel? Colors.white: Colors.transparent)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.filter_alt, size: 26, color: sel? Colors.white: Colors.white70), SizedBox(height:4), Text(filters[k]!['name']!, style: TextStyle(fontSize: 9, color: Colors.white), textAlign: TextAlign.center, maxLines:2)])));
        })),
        Container(padding: EdgeInsets.all(8), color: Color(0xFF0F2810), child: Column(children: [
          Row(children: [
            Expanded(child: ActionChip(avatar: Icon(Icons.auto_awesome, size:16, color: Colors.green), label: Text(filters[ai1]!['name']!, style: TextStyle(fontSize:11)), onPressed: ()=>setState(()=>filterKey=ai1), backgroundColor: Colors.green.withOpacity(0.25))),
            SizedBox(width:6),
            Expanded(child: ActionChip(avatar: Icon(Icons.auto_awesome, size:16, color: Colors.purple), label: Text(filters[ai2]!['name']!, style: TextStyle(fontSize:11)), onPressed: ()=>setState(()=>filterKey=ai2), backgroundColor: Colors.purple.withOpacity(0.25))),
          ]),
          Row(children: [
            Expanded(child: TextField(controller: textCtrl, decoration: InputDecoration(hintText: "Add Text e.g. Happy Birthday", isDense:true, border: OutlineInputBorder()), style: TextStyle(fontSize:12), onChanged: (v)=>overlayText=v)),
            SizedBox(width:6),
            ElevatedButton(onPressed: pickMusic, child: Text(musicPath==null?"🎵 Music":"🎵 Added", style: TextStyle(fontSize:10)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, minimumSize: Size(80, 36))),
            Switch(value: blurBg, onChanged: (v)=>setState(()=>blurBg=v), activeColor: Colors.purple),
            Text("Blur BG", style: TextStyle(fontSize:9)),
          ]),
        ])),
        Container(height: 30, width: double.infinity, decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.red, width: 1.5), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 8)]), child: processing? Stack(children: [
          FractionallySizedBox(widthFactor: progress/100, child: Container(color: Colors.red, alignment: Alignment.center, child: Text("${progress.toStringAsFixed(0)}% - 4K Exporting to Gallery...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
        ]) : Center(child: Text(status, style: TextStyle(color: Colors.white70, fontSize:11)))),
        Container(height: 40, color: Colors.black, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Icon(Icons.cut, color: Colors.white54, size:20), Icon(Icons.music_note, color: Colors.white54, size:20), Icon(Icons.text_fields, color: Colors.white, size:20), Icon(Icons.auto_fix_high, color: Colors.orange, size:20), Icon(Icons.blur_on, color: blurBg? Colors.purpleAccent: Colors.white54, size:20)])),
      ]),
    );
  }
}
