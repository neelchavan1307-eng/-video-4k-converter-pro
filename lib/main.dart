import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';

void main() => runApp(const MaterialApp(home: HatkeApp(), debugShowCheckedModeBanner: false));

class HatkeApp extends StatefulWidget {
  const HatkeApp({super.key});
  @override State<HatkeApp> createState() => _HatkeAppState();
}

class _HatkeAppState extends State<HatkeApp> {
  VideoPlayerController? ctrl;
  List<String> selected = [];
  bool exporting = false;
  String path = "";
  String status = "Ready";

  // FFmpeg चे खरे फिल्टर - हे Export ला लागतात
  final Map<String, String> ff = {
    "HD Dark": "eq=brightness=-0.12:contrast=1.35:saturation=0.85",
    "HD Light": "eq=brightness=0.12:contrast=1.15:saturation=1.1",
    "Quality Restore": "unsharp=5:5:1.0:5:5:0.0",
    "4K Sharp": "unsharp=7:7:1.2",
    "Oppenheimer": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131",
    "Black Panther": "eq=contrast=1.5:saturation=1.4",
    "Badburry": "hue=s=0.7:b=-5",
    "Freedom": "eq=saturation=1.6:contrast=1.1",
    "Green Orange": "colorbalance=rs=0.35:gs=0.1:bs=-0.25:rm=0.15:gm=0.05:bm=-0.1",
    "Sicily": "colorchannelmixer=1.25:0:0:0:0:1.15:0:0:0:0:0.9:0",
    "Kendall": "eq=brightness=0.06:contrast=1.25:saturation=1.3:gamma=0.95",
    "Retro Print": "curves=preset=strong_contrast",
    "Wong-kar-wai": "colorbalance=rs=0.4:gs=-0.15:bs=-0.25",
    "Glow": "eq=brightness=0.14:saturation=1.45",
    "Universal Suns": "colorbalance=rs=0.45:gs=0.25:bs=-0.15,eq=brightness=0.1:saturation=1.25",
    "Cinematic Glow": "eq=contrast=1.2:brightness=0.06:saturation=1.25",
    "Flash CCD": "eq=contrast=1.25:brightness=0.06:saturation=1.15",
  };

  // Live Preview साठी Color Filter - हे दिसण्यासाठी
  final Map<String, ColorFilter> preview = {
    "HD Dark": ColorFilter.matrix([0.85,0,0,0,0, 0,0.85,0,0,0, 0,0,0.75,0,0, 0,0,0,1,0]),
    "HD Light": ColorFilter.matrix([1.15,0,0,0,20, 0,1.15,0,0,20, 0,0,1.15,0,0, 0,0,0,1,0]),
    "Oppenheimer": ColorFilter.matrix([1.3,0.3,0,0,-15, 0.2,1.2,0,0,-15, 0,0,0.65,0,0, 0,0,0,1,0]),
    "Black Panther": ColorFilter.matrix([1.35,0,0,0,0, 0,1.35,0,0,0, 0,0,1.35,0,0, 0,0,0,1,0]),
    "Green Orange": ColorFilter.matrix([1.35,0.15,0,0,0, 0,1.25,0,0,0, 0,0,0.75,0,0, 0,0,0,1,0]),
    "Kendall": ColorFilter.matrix([1.18,0,0,0,22, 0,1.12,0,0,18, 0,0,1.02,0,0, 0,0,0,1,0]),
    "Glow": ColorFilter.matrix([1.28,0,0,0,25, 0,1.28,0,0,25, 0,0,1.28,0,0, 0,0,0,1,0]),
    "Universal Suns": ColorFilter.matrix([1.35,0.15,0,0,12, 0,1.25,0,0,12, 0,0,0.85,0,0, 0,0,0,1,0]),
    "Cinematic Glow": ColorFilter.matrix([1.2,0,0,0,10, 0,1.2,0,0,10, 0,0,1.2,0,0, 0,0,0,1,0]),
  };

  Future<void> pick() async {
    var res = await FilePicker.platform.pickFiles(type: FileType.video);
    if (res == null) return;
    path = res.files.single.path!;
    ctrl?.dispose();
    ctrl = VideoPlayerController.file(File(path));
    await ctrl!.initialize();
    await ctrl!.setLooping(true);
    await ctrl!.play();
    setState(() {});
  }

  // कितीही फिल्टर लावले तरी सगळे Join होतात
  String buildVF_4K() {
    List<String> list = [];
    for (var s in selected) { if (ff.containsKey(s)) list.add(ff[s]!); }
    if (list.isEmpty) list.add("eq=contrast=1.0");
    // शेवटी 4K Upscale - हाच खरा 4K करतो
    String filters = list.join(",");
    // 4K मध्ये Convert + Sharp
    return "$filters,scale=3840:2160:flags=lanczos:force_original_aspect_ratio=increase,crop=3840:2160,unsharp=5:5:0.8";
  }

  Future<void> export4K() async {
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("आधी Pick Video दाबा")));
      return;
    }
    setState(() { exporting = true; status = "4K Exporting..."; });
    await [Permission.storage, Permission.videos, Permission.photos, Permission.manageExternalStorage].request();

    var tmp = await getTemporaryDirectory();
    String out = "${tmp.path}/HATKE_4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String vf = buildVF_4K();

    // 4K Export Command - High Quality
    String cmd = "-y -i \"$path\" -vf \"$vf\" -c:v libx264 -profile:v high -level 5.1 -pix_fmt yuv420p -b:v 20M -c:a aac -b:a 192k -preset ultrafast \"$out\"";
    print("FFMPEG 4K CMD: $cmd");

    await FFmpegKit.execute(cmd).then((session) async {
      var code = await session.getReturnCode();
      if (ReturnCode.isSuccess(code)) {
        await Gal.putVideo(out, album: "HATKE");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ 4K Save झालं! Gallery > HATKE - ${selected.join("+")}")));
        setState(() => status = "Saved in 4K!");
      } else {
        var logs = await session.getFailStackTrace();
        print(logs);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export Fail - पुन्हा Try करा")));
        setState(() => status = "Fail");
      }
      setState(() => exporting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget videoBox;
    if (ctrl == null ||!ctrl!.value.isInitialized) {
      videoBox = Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.video_library, size: 70, color: Colors.white30),
        const SizedBox(height: 16),
        ElevatedButton.icon(icon: const Icon(Icons.folder_open), label: const Text("Pick Video - व्हिडिओ निवडा"), onPressed: pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
        const SizedBox(height: 8),
        const Text("आधी व्हिडिओ निवडा मग फिल्टर लावा", style: TextStyle(color: Colors.white54, fontSize: 12))
      ]));
    } else {
      Widget w = VideoPlayer(ctrl!);
      // Unlimited Filters Stack - Live Preview
      for (var s in selected) { var cf = preview[s]; if (cf!= null) w = ColorFiltered(colorFilter: cf, child: w); }
      videoBox = Stack(alignment: Alignment.center, children: [w, Positioned(top: 8, left: 8, child: Container(color: Colors.black54, padding: const EdgeInsets.all(4), child: Text("4K • ${ctrl!.value.size.width.toInt()}x${ctrl!.value.size.height.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 10))))]);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: const Color(0xFF6A1B9A), title: Text(selected.isEmpty? "HATKE - FILTERS LIVE" : "HATKE - ${selected.length} FILTERS LIVE", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.video_library), onPressed: pick), TextButton(onPressed: () => setState(() => selected.clear()), child: const Text("CLEAR", style: TextStyle(color: Colors.white)))]),
      body: Column(children: [
        Container(color: Colors.yellow, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text(selected.isEmpty? "फिल्टर निवडा - कितीही लावू शकता" : selected.join(" + "), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black), maxLines: 2)),
        Expanded(child: videoBox),
        Container(height: 230, color: const Color(0xFF1A1A1A), padding: const EdgeInsets.all(8), child: SingleChildScrollView(child: Wrap(spacing: 6, runSpacing: 6, children: [for (var k in ff.keys) FilterChip(label: Text(k, style: const TextStyle(fontSize: 10)), selected: selected.contains(k), selectedColor: Colors.yellow, backgroundColor: const Color(0xFF333333), labelStyle: TextStyle(color: selected.contains(k)? Colors.black : Colors.white, fontWeight: selected.contains(k)? FontWeight.bold : FontWeight.normal), onSelected: (v) { setState(() { v? selected.add(k) : selected.remove(k); }); })]))),
        Container(width: double.infinity, padding: const EdgeInsets.all(10), color: Colors.black, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), onPressed: exporting? null : export4K, child: exporting? Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black)), const SizedBox(width: 10), Text(status)]) : Text(selected.isEmpty? "EXPORT 4K - Ready" : "EXPORT - ${selected.join("+")} - 4K Ready", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)))
      ]),
    );
  }
}
