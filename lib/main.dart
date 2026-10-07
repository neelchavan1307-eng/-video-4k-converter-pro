import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: HatkeApp(), debugShowCheckedModeBanner: false));
}

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

  // TOTAL 70 FILTERS
  final Map<String, String> ff = {
    // तुझे 30
    "HD Dark": "eq=brightness=-0.12:contrast=1.35:saturation=0.85",
    "HD Light": "eq=brightness=0.12:contrast=1.15:saturation=1.1",
    "Quality Restore": "unsharp=5:5:1.0:5:5:0.0",
    "4K Sharp": "unsharp=7:7:1.2",
    "Oppenheimer": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131",
    "Black Panther": "eq=contrast=1.5:saturation=1.4",
    "Badbunny": "hue=s=0.7:b=-5",
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
    "Rain": "eq=brightness=-0.08:contrast=1.15:saturation=0.65,colorbalance=rs=-0.1:bs=0.15",
    "Green Lake": "eq=saturation=1.6:contrast=1.2,colorbalance=gs=0.35",
    "HD Pet": "eq=brightness=0.08:contrast=1.25:saturation=1.35,unsharp=5:5:0.8",
    "Calm & Collected": "eq=contrast=0.95:saturation=0.75:brightness=0.06",
    "Hasselblad 2": "eq=contrast=1.18:saturation=0.92",
    "God Rays": "eq=brightness=0.12:contrast=1.1,gblur=sigma=0.6",
    "Dracula": "eq=contrast=1.4:brightness=-0.08:saturation=0.7,colorbalance=rs=0.25",
    "Enhance": "eq=contrast=1.35:saturation=1.4:brightness=0.06,unsharp=5:5:0.7",
    "Enhanced": "eq=contrast=1.35:saturation=1.4:brightness=0.06,unsharp=5:5:0.7",
    "Retro Film": "colorchannelmixer=.8:.2:0:0:.1:.9:.1:0:0:.15:.85:0,eq=contrast=1.15:saturation=0.85",
    "Film": "curves=preset=vintage,eq=contrast=1.1:saturation=0.9",
    "Gold Coast": "colorbalance=rs=0.45:gs=0.2:bs=-0.2,eq=brightness=0.08:saturation=1.3",
    "Warm Yellow": "colorbalance=rs=0.35:gs=0.25:bs=-0.3,eq=brightness=0.1:saturation=1.25",

    // माझे नवीन 40 Pro Filters
    "Dune": "colorbalance=rs=0.3:gs=0.15:bs=-0.2,eq=contrast=1.2:brightness=0.05:saturation=0.85",
    "Interstellar": "eq=contrast=1.3:brightness=-0.05:saturation=0.8,colorbalance=bs=0.2",
    "Kodak Portra 400": "colorchannelmixer=1.1:0.1:0:0:0.05:1.0:0.05:0:0:0.05:0.95:0,eq=saturation=1.1:contrast=1.05",
    "Kodak Gold 200": "colorbalance=rs=0.2:gs=0.1:bs=-0.15,eq=saturation=1.25:contrast=1.1:brightness=0.06",
    "Fujifilm Eterna": "eq=saturation=0.7:contrast=0.95:brightness=0.04,colorbalance=gs=0.05",
    "Polaroid 600": "curves=preset=lighter,eq=saturation=0.85:contrast=0.9:brightness=0.08",
    "Venice": "colorbalance=rs=0.1:gs=0.1:bs=0.2,eq=contrast=1.15:saturation=1.2",
    "Tokyo Night": "colorbalance=rs=-0.15:gs=-0.05:bs=0.35,eq=contrast=1.25:saturation=1.3:brightness=-0.06",
    "Cyberpunk": "hue=h=15:s=1.6,eq=contrast=1.4",
    "Blade Runner": "colorbalance=rs=-0.2:gs=0.1:bs=0.4,eq=contrast=1.3:brightness=-0.08",
    "Matrix Green": "colorchannelmixer=0.3:0.7:0:0:0.3:0.8:0.2:0:0.2:0.4:0.3:0",
    "iPhone 15 Warm": "eq=brightness=0.07:saturation=1.2:contrast=1.1,colorbalance=rs=0.15:gs=0.08",
    "iPhone Vivid": "eq=saturation=1.5:contrast=1.2:brightness=0.04",
    "Warm Cozy": "colorbalance=rs=0.4:gs=0.15:bs=-0.25,eq=brightness=0.09:saturation=1.15",
    "Cool Breeze": "colorbalance=rs=-0.15:bs=0.25,eq=contrast=1.1:saturation=1.1:brightness=0.03",
    "Sunset Orange": "colorbalance=rs=0.5:gs=0.15:bs=-0.35,eq=saturation=1.4:contrast=1.15",
    "Moody Blue": "eq=contrast=1.2:saturation=0.85:brightness=-0.05,colorbalance=bs=0.3:rs=-0.15",
    "Forest Green": "colorbalance=gs=0.4:bs=-0.1:rs=-0.1,eq=saturation=1.3:contrast=1.15",
    "Desert Sand": "colorbalance=rs=0.3:gs=0.15:bs=-0.25,eq=contrast=1.1:brightness=0.08:saturation=1.05",
    "Arctic White": "eq=brightness=0.18:contrast=0.9:saturation=0.6",
    "Tropical": "eq=saturation=1.7:contrast=1.2:brightness=0.05,hue=s=1.2",
    "Soft Skin": "eq=brightness=0.08:contrast=0.95:saturation=0.9,gblur=sigma=0.3",
    "Tan Glow": "colorbalance=rs=0.25:gs=0.12:bs=-0.15,eq=saturation=1.2:brightness=0.07",
    "Rosy Cheeks": "colorbalance=rs=0.2:gs=-0.05:bs=0.05,eq=saturation=1.25",
    "Creamy Skin": "eq=brightness=0.1:contrast=0.92:saturation=0.95,colorbalance=rs=0.12:gs=0.06",
    "Honey": "colorbalance=rs=0.35:gs=0.2:bs=-0.2,eq=saturation=1.2:brightness=0.06",
    "Bronze": "colorchannelmixer=1.2:0.1:0:0:0.05:1.0:0.1:0:0:0:0.8:0,eq=contrast=1.15",
    "Aesthetic": "eq=saturation=0.8:contrast=1.05:brightness=0.06,curves=preset=medium_contrast",
    "Pastel": "eq=saturation=0.7:brightness=0.12:contrast=0.9",
    "Candy": "eq=saturation=1.8:contrast=1.15:brightness=0.06",
    "Midnight": "eq=brightness=-0.15:contrast=1.4:saturation=0.6,colorbalance=bs=0.2",
    "Gotham": "eq=contrast=1.5:brightness=-0.12:saturation=0.5",
    "Noir": "colorchannelmixer=0.33:0.33:0.33:0:0.33:0.33:0.33:0:0.33:0.33:0.33:0,eq=contrast=1.4",
    "Sin City": "eq=saturation=0:contrast=1.6,curves=preset=strong_contrast",
    "Joker": "colorbalance=rs=0.15:gs=0.25:bs=-0.1,eq=contrast=1.3:saturation=1.4",
    "Sepia Deep": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131,eq=contrast=1.2",
    "B&W High Contrast": "colorchannelmixer=0.33:0.33:0.33:0:0.33:0.33:0.33:0:0.33:0.33:0.33:0,eq=contrast=1.8:brightness=-0.05",
    "Silver": "eq=saturation=0:contrast=1.2:brightness=0.08",
    "Platinum": "eq=saturation=0.15:contrast=1.1:brightness=0.1,gblur=sigma=0.2",
    "Rust": "colorbalance=rs=0.4:gs=0.05:bs=-0.3,eq=contrast=1.25:saturation=1.15",
  };

  @override void dispose() { ctrl?.dispose(); super.dispose(); }

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

  String buildVF_4K() {
    List<String> list = [];
    for (var s in selected) { if (ff.containsKey(s)) list.add(ff[s]!); }
    if (list.isEmpty) list.add("eq=contrast=1.0");
    return "${list.join(",")},scale=3840:2160:flags=lanczos,crop=3840:2160,unsharp=5:5:0.8";
  }

  Future<void> export4K() async {
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("आधी Pick Video दाबा")));
      return;
    }
    setState(() { exporting = true; status = "4K Exporting..."; });
    await [Permission.storage, Permission.videos, Permission.photos].request();
    var tmp = await getTemporaryDirectory();
    String out = "${tmp.path}/HATKE_4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String vf = buildVF_4K();
    String cmd = "-y -i \"$path\" -vf \"$vf\" -c:v libx264 -profile:v high -level 5.1 -pix_fmt yuv420p -b:v 20M -c:a aac -b:a 192k -preset ultrafast \"$out\"";
    await FFmpegKit.execute(cmd).then((session) async {
      var code = await session.getReturnCode();
      if (ReturnCode.isSuccess(code)) {
        await Gal.putVideo(out, album: "HATKE 70 FILTERS");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ 4K Save! ${selected.length} Filters: ${selected.join("+")}")));
        setState(() => status = "Saved 4K!");
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export Fail")));
        setState(() => status = "Fail");
      }
      setState(() => exporting = false);
    });
  }

  @override Widget build(BuildContext context) {
    Widget videoBox;
    if (ctrl == null ||!ctrl!.value.isInitialized) {
      videoBox = Center(child: ElevatedButton.icon(icon: const Icon(Icons.folder_open), label: const Text("Pick Video"), onPressed: pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14))));
    } else {
      Widget w = VideoPlayer(ctrl!);
      videoBox = w;
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: const Color(0xFF6A1B9A), title: Text(selected.isEmpty? "HATKE - 70 FILTERS" : "${selected.length} FILTERS LIVE", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.video_library), onPressed: pick), TextButton(onPressed: () => setState(() => selected.clear()), child: const Text("CLEAR", style: TextStyle(color: Colors.white)))]),
      body: Column(children: [
        Container(color: Colors.yellow, width: double.infinity, padding: const EdgeInsets.all(6), child: Text(selected.isEmpty? "70 फिल्टर - कितीही एकत्र लावा - 4K Export" : selected.join(" + "), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black), maxLines: 2)),
        Expanded(child: videoBox),
        Container(height: 300, color: const Color(0xFF1A1A1A), padding: const EdgeInsets.all(8), child: SingleChildScrollView(child: Wrap(spacing: 5, runSpacing: 5, children: [for (var k in ff.keys) FilterChip(label: Text(k, style: const TextStyle(fontSize: 9)), selected: selected.contains(k), selectedColor: Colors.yellow, backgroundColor: const Color(0xFF333333), labelStyle: TextStyle(color: selected.contains(k)? Colors.black : Colors.white, fontSize: 9), onSelected: (v) { setState(() { v? selected.add(k) : selected.remove(k); }); })]))),
        Container(width: double.infinity, padding: const EdgeInsets.all(10), color: Colors.black, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))), onPressed: exporting? null : export4K, child: Text(exporting? status : selected.isEmpty? "EXPORT 4K - 70 Filters Ready" : "EXPORT ${selected.length} FILTERS - 4K", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)))
      ]),
    );
  }
}
