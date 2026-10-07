import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const MaterialApp(home: HatkeApp(), debugShowCheckedModeBanner: false));

class HatkeApp extends StatefulWidget { @override State<HatkeApp> createState() => _HatkeAppState(); }

class _HatkeAppState extends State<HatkeApp> {
  VideoPlayerController? ctrl;
  List<String> selected = ["HD Dark"];
  bool exporting = false;
  String path = "";

  final Map<String, String> ff = {
    "HD Dark": "eq=brightness=-0.15:contrast=1.3:saturation=0.8",
    "Quality Restore": "unsharp=5:5:1.0",
    "4K": "scale=iw:ih:flags=lanczos,unsharp=5:5:0.6",
    "HD Light": "eq=brightness=0.1:contrast=1.1",
    "Oppenheimer": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131",
    "Wong-kar-wai": "colorbalance=rs=0.3:gs=-0.1:bs=-0.2",
    "Black Panther": "eq=contrast=1.4:saturation=1.3",
    "Badburry": "eq=saturation=0.6",
    "Freedom": "eq=saturation=1.5",
    "Hasselblad 2": "eq=saturation=1.2",
    "Green Orange": "colorbalance=rs=0.3:gs=0.1:bs=-0.2",
    "Sicily": "eq=contrast=1.2:saturation=1.1",
    "Kendall": "eq=brightness=0.05:contrast=1.2:saturation=1.2",
    "Retro Print": "eq=contrast=1.3",
    "Glow": "eq=brightness=0.12:saturation=1.4",
    "Universal Suns": "eq=brightness=0.08:saturation=1.2,colorbalance=rs=0.4",
    "Cinematic Glow": "eq=contrast=1.15:brightness=0.05:saturation=1.2",
    "Flash CCD": "eq=contrast=1.2:brightness=0.05",
  };

  final Map<String, ColorFilter> preview = {
    "HD Dark": ColorFilter.matrix([0.85,0,0,0,0, 0,0.85,0,0,0, 0,0,0.75,0,0, 0,0,0,1,0]),
    "HD Light": ColorFilter.matrix([1.1,0,0,0,15, 0,1.1,0,0,15, 0,0,1.1,0,0, 0,0,0,1,0]),
    "Oppenheimer": ColorFilter.matrix([1.25,0.25,0,0,-10, 0.15,1.15,0,0,-10, 0,0,0.7,0,0, 0,0,0,1,0]),
    "Kendall": ColorFilter.matrix([1.15,0,0,0,20, 0,1.1,0,0,15, 0,0,1.0,0,0, 0,0,0,1,0]),
    "Green Orange": ColorFilter.matrix([1.3,0,0,0,0, 0,1.2,0,0,0, 0,0,0.8,0,0, 0,0,0,1,0]),
    "Glow": ColorFilter.matrix([1.25,0,0,0,20, 0,1.25,0,0,20, 0,0,1.25,0,0, 0,0,0,1,0]),
    "Universal Suns": ColorFilter.matrix([1.3,0.1,0,0,10, 0,1.2,0,0,10, 0,0,0.9,0,0, 0,0,0,1,0]),
  };

  Future<void> pick() async {
    var res = await FilePicker.platform.pickFiles(type: FileType.video);
    if(res==null) return;
    path = res.files.single.path!;
    ctrl?.dispose();
    ctrl = VideoPlayerController.file(File(path));
    await ctrl!.initialize();
    await ctrl!.setLooping(true);
    await ctrl!.play();
    setState((){});
  }

  String buildVF(){
    List<String> list = [];
    for(var s in selected){ if(ff.containsKey(s)) list.add(ff[s]!); }
    return list.join(",");
  }

  Future<void> export() async {
    if(path.isEmpty){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("आधी Pick Video दाबा"))); return; }
    setState(()=> exporting = true);
    await [Permission.storage, Permission.videos, Permission.photos, Permission.manageExternalStorage].request();
    var tmp = await getTemporaryDirectory();
    String out = "${tmp.path}/HATKE_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String vf = buildVF();
    String cmd = "-y -i \"$path\" -vf \"$vf\" -c:v libx264 -c:a aac -preset ultrafast \"$out\"";
    await FFmpegKit.execute(cmd).then((s) async {
      var code = await s.getReturnCode();
      if(ReturnCode.isSuccess(code)){
        var dir = Directory("/storage/emulated/0/DCIM/HATKE");
        if(!await dir.exists()) await dir.create(recursive: true);
        String finalP = "${dir.path}/HATKE_${DateTime.now().millisecondsSinceEpoch}.mp4";
        await File(out).copy(finalP);
        await GallerySaver.saveVideo(finalP);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Save झालं - DCIM/HATKE")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export Fail")));
      }
      setState(()=> exporting = false);
    });
  }

  @override Widget build(BuildContext context){
    Widget videoBox;
    if(ctrl==null ||!ctrl!.value.isInitialized){
      videoBox = Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.video_library, size: 60, color: Colors.white54),
        SizedBox(height: 12),
        ElevatedButton.icon(icon: Icon(Icons.folder_open), label: Text("Pick Video"), onPressed: pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black)),
      ]));
    } else {
      Widget w = VideoPlayer(ctrl!);
      for(var s in selected){ var cf = preview[s]; if(cf!=null) w = ColorFiltered(colorFilter: cf, child: w); }
      videoBox = w;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.purple, title: Text("HATKE - ${selected.length} FILTERS LIVE", style: TextStyle(fontSize: 12)), actions: [IconButton(icon: Icon(Icons.video_library), onPressed: pick)]),
      body: Column(children: [
        Container(color: Colors.yellow, width: double.infinity, padding: EdgeInsets.all(6), child: Text(selected.join(" + "), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 2)),
        Expanded(child: videoBox),
        Container(height: 210, color: Color(0xFF1A1A1A), padding: EdgeInsets.all(8), child: SingleChildScrollView(child: Wrap(spacing: 6, runSpacing: 6, children: [
          for(var k in ff.keys)
            FilterChip(label: Text(k, style: TextStyle(fontSize: 10)), selected: selected.contains(k), selectedColor: Colors.yellow, backgroundColor: Color(0xFF333333), labelStyle: TextStyle(color: selected.contains(k)? Colors.black: Colors.white), onSelected: (v){ setState(()=> v? selected.add(k): selected.remove(k)); })
        ]))),
        Container(padding: EdgeInsets.all(10), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), onPressed: exporting? null : export, child: exporting? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)): Text("EXPORT - ${selected.join("+")} - Ready", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), overflow: TextOverflow.ellipsis)))
      ]),
    );
  }
}
