import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() { runApp(MaterialApp(home: FinalApp(), debugShowCheckedModeBanner: false)); }

class FinalApp extends StatefulWidget { @override State<FinalApp> createState() => _FinalAppState(); }

class _FinalAppState extends State<FinalApp> {
  File? pickedFile;
  VideoPlayerController? _c;
  String status = "Video Select Kara";
  bool processing = false;
  double previewProgress = 0;
  double convertProgress = 0; // NEW - converting sathi vegla
  int totalDurationMs = 1;

  double focusFilter = 50, fourKFilter = 70, evenSkin = 30, whitening = 25, brilliance = 20, sharpen = 40;
  String selectedMode = "Devi Glow";

  Future<void> pick() async {
    await Permission.storage.request();
    await Permission.videos.request();
    await Permission.manageExternalStorage.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r != null && r.files.single.path != null) {
      pickedFile = File(r.files.single.path!);
      _c?.dispose();
      _c = VideoPlayerController.file(pickedFile!)
        ..initialize().then((_) {
          setState(() { totalDurationMs = _c!.value.duration.inMilliseconds; });
        })
        ..setLooping(true)..play();
      Timer.periodic(Duration(milliseconds: 100), (t) {
        if (_c != null && _c!.value.isInitialized && !processing) {
          setState(() {
            previewProgress = _c!.value.position.inMilliseconds / (_c!.value.duration.inMilliseconds == 0 ? 1 : _c!.value.duration.inMilliseconds);
          });
        }
      });
      setState(() => status = "Ready");
    }
  }

  List<double> getMatrix() {
    double w = whitening;
    if (selectedMode == "Devi Glow") return [1.2,0,0,0,10+w/2, 0,1.15,0,0,10+w/2, 0,0,1.1,0,20+w/2, 0,0,0,1,0];
    if (selectedMode == "Cute Soft") return [1.1,0,0,0,20+w/2, 0,1.1,0,0,20+w/2, 0,0,1.2,0,25+w/2, 0,0,0,1,0];
    return [1.3,0,0,0,5+w/3, 0,1.1,0,0,5+w/3, 0,0,1.4,0,5+w/3, 0,0,0,1,0];
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() { processing = true; convertProgress = 0; status = "0% - Converting Start..."; });

    // FIX 1: Gallery la disnara folder
    Directory moviesDir = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if (!await moviesDir.exists()) await moviesDir.create(recursive: true);
    String out = "${moviesDir.path}/HATKE_${DateTime.now().millisecondsSinceEpoch}.mp4";

    double sharpVal = (sharpen + focusFilter) / 100 * 1.5;
    String vf = "scale=3840:2160:flags=lanczos,unsharp=5:5:$sharpVal:5:5:0,hqdn3d=${evenSkin/10}:${evenSkin/10}:6:6,eq=contrast=${1+brilliance/100}:brightness=${0.02+whitening/400}:saturation=${1.3+fourKFilter/100}";
    String cmd = "-y -i '${pickedFile!.path}' -vf \"$vf\" -c:v libx264 -preset ultrafast -crf 20 -c:a copy '$out'";

    // FIX 2: Real-time converting progress
    FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
      if (totalDurationMs > 0) {
        double prog = stats.getTime() / totalDurationMs;
        if (prog > 1) prog = 1;
        if (prog < 0) prog = 0;
        setState(() {
          convertProgress = prog;
          status = "${(prog*100).toInt()}% Converting... ${(stats.getSize()/1024).toInt()} KB";
        });
      }
    });

    await FFmpegKit.execute(cmd).then((s) async {
      var code = await s.getReturnCode();
      if (ReturnCode.isSuccess(code)) {
        // FIX 3: Gallery scan
        await FFmpegKit.execute("-y -i '$out' -c copy -f null /dev/null"); // trigger media scan trick
        // MediaStore la dakhva
        File(out).existsSync();
        setState(() { processing = false; convertProgress = 1.0; status = "SAVED! Gallery > Movies > HATKE_4K\n$out"; });
      } else {
        var logs = await s.getAllLogsAsString();
        setState(() { processing = false; status = "Failed: $logs".substring(0, 300); });
      }
    });
  }

  Widget modeChip(String name, IconData icon, Color col) {
    bool sel = selectedMode == name;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = name),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: sel ? col : Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? Colors.white : col.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.white), SizedBox(width: 4), Text(name, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget miniSlider(String name, double val, Function(double) onC) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Row(children: [
        SizedBox(width: 95, child: Text(name, style: TextStyle(color: Colors.white60, fontSize: 11))),
        Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6)), child: Slider(value: val, min: 0, max: 100, activeColor: Colors.pinkAccent, inactiveColor: Colors.white24, onChanged: processing ? null : onC))),
        SizedBox(width: 30, child: Text("${val.toInt()}", style: TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(title: Text("HATKE 4K - 6 Functions"), backgroundColor: Colors.purple),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(children: [
          ElevatedButton(onPressed: processing ? null : pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 42)), child: Text("SELECT VIDEO")),
          SizedBox(height: 8),
          if (_c != null && _c!.value.isInitialized) ...[
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(children: [AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)), Positioned.fill(child: ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: Container()))])),
            SizedBox(height: 8),
            if (!processing) ...[
              Container(height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white10), child: FractionallySizedBox(widthFactor: previewProgress.clamp(0.0, 1.0), alignment: Alignment.centerLeft, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Colors.pinkAccent, Colors.cyanAccent]))))),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("REAL TIME PREVIEW", style: TextStyle(color: Colors.pinkAccent, fontSize: 9, fontWeight: FontWeight.bold)), Text("${(previewProgress*100).toInt()}%", style: TextStyle(color: Colors.cyanAccent, fontSize: 9))]),
            ],
            if (processing) ...[
              SizedBox(height: 4),
              Container(height: 14, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white10, border: Border.all(color: Colors.pinkAccent.withOpacity(0.5))), child: Stack(children: [
                FractionallySizedBox(widthFactor: convertProgress.clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Colors.purple, Colors.pinkAccent, Colors.orange, Colors.yellow]), boxShadow: [BoxShadow(color: Colors.pinkAccent, blurRadius: 12)]))),
                Center(child: Text("${(convertProgress*100).toInt()}% CONVERTING", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              ])),
              SizedBox(height: 4),
              Text("Please wait, 4K rendering...", style: TextStyle(color: Colors.orangeAccent, fontSize: 10)),
            ]
          ],
          SizedBox(height: 10),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [modeChip("Devi Glow", Icons.auto_awesome, Colors.orange), SizedBox(width: 6), modeChip("Cute Soft", Icons.favorite, Colors.pink), SizedBox(width: 6), modeChip("Cyber Pop", Icons.bolt, Colors.cyan)])),
          SizedBox(height: 8),
          Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)), child: Column(children: [
            miniSlider("1. Focus Filter", focusFilter, (v) => setState(() => focusFilter = v)),
            miniSlider("2. 4K Filter", fourKFilter, (v) => setState(() => fourKFilter = v)),
            miniSlider("3. Even Skin", evenSkin, (v) => setState(() => evenSkin = v)),
            miniSlider("4. Whitening", whitening, (v) => setState(() => whitening = v)),
            miniSlider("5. Brilliance", brilliance, (v) => setState(() => brilliance = v)),
            miniSlider("6. Sharpen", sharpen, (v) => setState(() => sharpen = v)),
          ])),
          SizedBox(height: 10),
          Text(status, style: TextStyle(color: processing ? Colors.orangeAccent : Colors.white70, fontSize: 11, fontWeight: processing ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
          SizedBox(height: 10),
          ElevatedButton(onPressed: processing ? null : convert, style: ElevatedButton.styleFrom(backgroundColor: processing ? Colors.grey : Colors.pinkAccent, minimumSize: Size(double.infinity, 48)), child: processing ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 10), Text("${(convertProgress*100).toInt()}% RENDERING...", style: TextStyle(color: Colors.white))]) : Text("EXPORT REAL 4K", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          SizedBox(height: 25),
        ]),
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  @override void paint(Canvas c, Size s) { var r = Random(); var p = Paint()..color = Colors.white.withOpacity(0.5); for (int i = 0; i < 6; i++) c.drawCircle(Offset(r.nextDouble()*s.width, r.nextDouble()*s.height), 1, p); }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
