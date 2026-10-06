import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() { runApp(MaterialApp(home: FinalApp(), debugShowCheckedModeBanner: false)); }

class FinalApp extends StatefulWidget { @override State<FinalApp> createState() => _FinalAppState(); }

class _FinalAppState extends State<FinalApp> {
  File? pickedFile;
  VideoPlayerController? _c;
  String status = "Video Select Kara";
  bool processing = false;
  bool showComparison = true;
  double previewProgress = 0;
  double convertProgress = 0;

  double focusFilter = 50, fourKFilter = 70, evenSkin = 30, whitening = 25, brilliance = 20, sharpen = 40;
  String selectedMode = "Devi Glow";

  Future<void> pick() async {
    await [Permission.storage, Permission.videos, Permission.manageExternalStorage].request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r!= null && r.files.single.path!= null) {
      pickedFile = File(r.files.single.path!);
      _c?.dispose();
      _c = VideoPlayerController.file(pickedFile!)
       ..initialize().then((_) => setState(() {}))
       ..setLooping(true)
       ..play();
      Timer.periodic(Duration(milliseconds: 200), (t) {
        if (_c!= null && _c!.value.isInitialized) {
          setState(() {
            previewProgress = _c!.value.position.inMilliseconds / (_c!.value.duration.inMilliseconds == 0? 1 : _c!.value.duration.inMilliseconds);
          });
        }
      });
      setState(() => status = "Ready - Export dabaya");
    }
  }

  List<double> getMatrix() {
    double w = whitening;
    if (selectedMode == "Devi Glow") {
      return [1.4,0,0,0,15+w, 0,1.2,0,0,10+w, 0,0,0.9,0,-5+w, 0,0,0,1,0];
    } else if (selectedMode == "Cute Soft") {
      return [1.3,0.1,0.1,0,25+w, 0.1,1.2,0.1,0,20+w, 0.1,0.1,1.4,0,30+w, 0,0,0,1,0];
    } else {
      return [1.6,-0.1,0,0,5+w/2, -0.1,1.1,0,0,5+w/2, 0,0,1.8,0,5+w/2, 0,0,0,1,0];
    }
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() { processing = true; convertProgress = 0.01; status = "1% Starting..."; });

    FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
      if (stats.getTime() > 0 && _c!= null) {
        double p = stats.getTime() / _c!.value.duration.inMilliseconds;
        if (p > 0.99) p = 0.99;
        if (p < 0) p = 0;
        setState(() {
          convertProgress = p;
          status = "${(p*100).toInt()}% Converting...";
        });
      }
    });

    Directory moviesDir = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if (!await moviesDir.exists()) await moviesDir.create(recursive: true);
    String out = "${moviesDir.path}/HATKE_${DateTime.now().millisecondsSinceEpoch}.mp4";

    double sharpVal = (sharpen + focusFilter) / 100 * 1.5;

    // FIX - DABLA JAU NAYE MHANUN
    bool isPortrait = _c!.value.size.height > _c!.value.size.width;
    String scaleFilter = isPortrait
       ? "scale=1080:1920:flags=lanczos:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black"
        : "scale=1920:1080:flags=lanczos:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=black";

    String vf = "$scaleFilter,unsharp=5:5:$sharpVal:5:5:0,eq=contrast=${1+brilliance/100}:brightness=${0.02+whitening/400}:saturation=${1.3+fourKFilter/100}";

    String cmd = "-y -i '${pickedFile!.path}' -vf \"$vf\" -c:v libx264 -preset superfast -crf 23 -c:a copy '$out'";

    await FFmpegKit.execute(cmd).then((s) async {
      FFmpegKitConfig.enableStatisticsCallback(null);
      if (ReturnCode.isSuccess(await s.getReturnCode())) {
        setState(() { convertProgress = 1.0; processing = false; status = "DONE! Gallery > Movies > HATKE_4K\n$out"; });
      } else {
        setState(() { processing = false; status = "Failed"; });
      }
    });
  }

  Widget modeChip(String name, IconData icon, Color col) {
    bool sel = selectedMode == name;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = name),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel? col : Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel? Colors.white : col.withOpacity(0.6)),
          boxShadow: sel? [BoxShadow(color: col, blurRadius: 12)] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: Colors.white),
          SizedBox(width: 5),
          Text(name, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }

  Widget miniSlider(String name, double val, Function(double) onC) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 100, child: Text(name, style: TextStyle(color: Colors.white70, fontSize: 11))),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(trackHeight: 3, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7)),
            child: Slider(value: val, min: 0, max: 100, activeColor: Colors.pinkAccent, inactiveColor: Colors.white24, onChanged: (v) => setState(() => onC(v))),
          ),
        ),
        SizedBox(width: 32, child: Text("${val.toInt()}", style: TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(title: Text("HATKE 4K - No Dabla"), backgroundColor: Colors.purple),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(children: [
          ElevatedButton(onPressed: processing? null : pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 44)), child: Text("SELECT VIDEO")),
          SizedBox(height: 8),
          if (_c!= null && _c!.value.isInitialized)...[
            // SPLIT VIEW PREVIEW
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(children: [
                AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)),
                if (!showComparison) Positioned.fill(child: ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: Container())),
                if (showComparison)
                  Positioned.fill(
                    child: Row(children: [
                      Expanded(
                        child: Stack(children: [
                          AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)),
                          Positioned(bottom: 4, left: 4, child: Container(color: Colors.black54, padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text("REAL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
                        ]),
                      ),
                      Container(width: 2, color: Colors.white),
                      Expanded(
                        child: Stack(children: [
                          ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!))),
                          Positioned(bottom: 4, left: 4, child: Container(color: Colors.pink, padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text("FILTERED", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
                        ]),
                      ),
                    ]),
                  ),
              ]),
            ),
            SizedBox(height: 6),
            ElevatedButton(onPressed: () => setState(() => showComparison =!showComparison), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF222222), minimumSize: Size(double.infinity, 30)), child: Text(showComparison? "SINGLE VIEW" : "COMPARE REAL vs FILTERED", style: TextStyle(fontSize: 10, color: Colors.white70))),
            SizedBox(height: 6),
            Container(
              height: processing? 16 : 8,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white10, border: processing? Border.all(color: Colors.pinkAccent) : null),
              child: Stack(children: [
                FractionallySizedBox(widthFactor: (processing? convertProgress : previewProgress).clamp(0.0, 1.0), alignment: Alignment.centerLeft, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: processing? [Colors.purple, Colors.pinkAccent, Colors.orange, Colors.yellow] : [Colors.pinkAccent, Colors.cyanAccent]), boxShadow: [BoxShadow(color: Colors.pinkAccent, blurRadius: processing? 12 : 4)]))),
                if (processing) Center(child: Text("${(convertProgress * 100).toInt()}% CONVERTING", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              ]),
            ),
            SizedBox(height: 4),
            Text(processing? status : "REAL TIME PREVIEW ${(previewProgress * 100).toInt()}%", style: TextStyle(color: processing? Colors.orangeAccent : Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
          SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [modeChip("Devi Glow", Icons.auto_awesome, Colors.orange), SizedBox(width: 8), modeChip("Cute Soft", Icons.favorite, Colors.pink), SizedBox(width: 8), modeChip("Cyber Pop", Icons.bolt, Colors.cyan)])),
          SizedBox(height: 10),
          Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: Column(children: [
            miniSlider("1. Focus Filter", focusFilter, (v) => focusFilter = v),
            miniSlider("2. 4K Filter", fourKFilter, (v) => fourKFilter = v),
            miniSlider("3. Even Skin", evenSkin, (v) => evenSkin = v),
            miniSlider("4. Whitening", whitening, (v) => whitening = v),
            miniSlider("5. Brilliance", brilliance, (v) => brilliance = v),
            miniSlider("6. Sharpen", sharpen, (v) => sharpen = v),
          ])),
          SizedBox(height: 12),
          Text(status, style: TextStyle(color: processing? Colors.orangeAccent : Colors.white70, fontSize: 11), textAlign: TextAlign.center),
          SizedBox(height: 12),
          ElevatedButton(onPressed: processing? null : convert, style: ElevatedButton.styleFrom(backgroundColor: processing? Colors.grey : Colors.pinkAccent, minimumSize: Size(double.infinity, 50)), child: processing? Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 10), Text("${(convertProgress * 100).toInt()}% RENDERING")]) : Text("EXPORT REAL 4K", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          SizedBox(height: 25),
        ]),
      ),
    );
  }
}
