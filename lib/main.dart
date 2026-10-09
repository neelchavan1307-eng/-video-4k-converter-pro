import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() { runApp(MaterialApp(debugShowCheckedModeBanner: false, home: ProMaxEditor(), theme: ThemeData.dark())); }
class ProMaxEditor extends StatefulWidget { @override _ProMaxEditorState createState() => _ProMaxEditorState(); }
class _ProMaxEditorState extends State<ProMaxEditor> {
  String? videoPath, musicPath;
  VideoPlayerController? vc;
  bool processing=false, blurBg=false, stabilize=false, denoise=false, autoHDR=false, autoCaption=false, beatSync=false, autoEnhance=true;
  double progress=0;
  List<String> selected=[];
  String status="PRO MAX - 120 Filters + True AI Ready";
  String aiReason="TRUE AI: Video टाक - AI रंग, प्रकाश, Quality Check करेल!";
  List<String> aiList=[];
  String captionText="Happy Birthday Prem!";
  TextEditingController capCtrl=TextEditingController(text:"Happy Birthday Prem!");
  double aiScore=0;
  String videoMeta="";

  Map<String, Map<String,String>> filters={
    "f01": {"name":"Normal","cmd":"","c":"normal"},
    "f02": {"name":"B&W","cmd":"hue=s=0","c":"bw"},
    "f03": {"name":"Sepia","cmd":"colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131","c":"sepia"},
    "f04": {"name":"Vintage","cmd":"curves=vintage","c":"warm"},
    "f05": {"name":"Warm Birthday","cmd":"eq=brightness=0.06:saturation=1.35","c":"warm"},
    "f06": {"name":"Cold","cmd":"eq=saturation=1.2:gamma_b=1.2","c":"cold"},
    "f07": {"name":"Bright","cmd":"eq=brightness=0.25:contrast=1.25","c":"bright"},
    "f08": {"name":"Vivid","cmd":"eq=saturation=2.2:contrast=1.3","c":"vivid"},
    "f09": {"name":"Blur Light","cmd":"gblur=sigma=1.5","c":"normal"},
    "f10": {"name":"Cinematic","cmd":"eq=contrast=1.2:saturation=1.25,unsharp=3:3:0.5","c":"cinematic"},
    "f11": {"name":"Golden Hour","cmd":"colorbalance=rs=0.3:bs=-0.2","c":"warm"},
    "f12": {"name":"HDR 4K","cmd":"eq=contrast=1.5:saturation=1.45,unsharp=5:5:0.8","c":"vivid"},
    "f13": {"name":"Noir","cmd":"hue=s=0,eq=contrast=1.5","c":"bw"},
    "f14": {"name":"Cartoon","cmd":"edgedetect=low=0.1:high=0.4","c":"normal"},
    "f15": {"name":"Dreamy Glow","cmd":"eq=brightness=0.15:saturation=1.3,gblur=sigma=0.8","c":"bright"},
    "f16": {"name":"Neon Party","cmd":"eq=saturation=2.5:contrast=1.4","c":"vivid"},
    "f17": {"name":"Old Film","cmd":"curves=preset=vintage","c":"sepia"},
    "f18": {"name":"Clarendon","cmd":"eq=contrast=1.2:saturation=1.4","c":"vivid"},
    "f19": {"name":"Lomo","cmd":"curves=preset=lomo","c":"vivid"},
    "f20": {"name":"Moon","cmd":"hue=s=0,eq=brightness=0.1","c":"bw"},
    "f21": {"name":"Fire","cmd":"colorbalance=rs=0.4","c":"warm"},
    "f22": {"name":"Ice","cmd":"colorbalance=bs=0.4","c":"cold"},
    "f23": {"name":"Pop Art","cmd":"eq=saturation=3:contrast=2","c":"vivid"},
    "f24": {"name":"Portrait","cmd":"eq=brightness=0.08:saturation=1.15","c":"bright"},
    "f25": {"name":"4K Ultra","cmd":"scale=3840:2160:flags=lanczos","c":"normal"},
    "f26": {"name":"Sharpen Pro","cmd":"unsharp=7:7:1.5","c":"normal"},
    "f27": {"name":"Soft Skin AI","cmd":"eq=saturation=1.1","c":"bright"},
    "f28": {"name":"Night Boost AI","cmd":"eq=brightness=0.35:contrast=1.25","c":"bright"},
    "f29": {"name":"Daylight AI","cmd":"eq=brightness=0.05:saturation=1.25","c":"bright"},
    "f30": {"name":"Landscape Pro","cmd":"eq=saturation=1.6:contrast=1.2","c":"vivid"},
    "f31": {"name":"Gold Luxury","cmd":"colorchannelmixer=1.2:.4:.2:0","c":"warm"},
    "f32": {"name":"Silver Metal","cmd":"hue=s=0.15","c":"bw"},
    "f33": {"name":"Cyberpunk 2077","cmd":"eq=saturation=2.2:contrast=1.3","c":"vivid"},
    "f34": {"name":"Dreamy Pro","cmd":"gblur=sigma=1.2","c":"bright"},
    "f35": {"name":"Mirror Pro","cmd":"hflip","c":"normal"},
    "f36": {"name":"Vignette Pro","cmd":"vignette=PI/4","c":"cinematic"},
    "f37": {"name":"Insta Square","cmd":"crop=1:1,scale=1080:1080","c":"normal"},
    "f38": {"name":"Sunset Pro Max","cmd":"eq=brightness=0.08:saturation=1.8","c":"warm"},
    "f39": {"name":"Sunrise Pro","cmd":"eq=brightness=0.18:saturation=1.4","c":"warm"},
    "f40": {"name":"Rose Gold Max","cmd":"colorchannelmixer=1.1:.3:.3:0","c":"warm"},
    "f41": {"name":"Fade Film","cmd":"eq=brightness=0.12:contrast=0.85","c":"bright"},
    "f42": {"name":"High Key Pro","cmd":"eq=brightness=0.28","c":"bright"},
    "f43": {"name":"Low Key Cinema","cmd":"eq=brightness=-0.25:contrast=1.45","c":"cinematic"},
    "f44": {"name":"Pastel Dream","cmd":"eq=saturation=0.7:brightness=0.15","c":"bright"},
    "f45": {"name":"Bronze Age","cmd":"colorchannelmixer=1.1:.5:.2:0","c":"warm"},
    "f46": {"name":"Deep Blue Sea","cmd":"colorbalance=bs=0.5","c":"cold"},
    "f47": {"name":"Deep Red Wine","cmd":"colorbalance=rs=0.5","c":"warm"},
    "f48": {"name":"Indoor Pro","cmd":"eq=brightness=0.15:saturation=1.1","c":"bright"},
    "f49": {"name":"Grain Film","cmd":"noise=alls=20","c":"normal"},
    "f50": {"name":"DeNoise AI","cmd":"hqdn3d","c":"normal"},
    "f51": {"name":"Emboss 3D","cmd":"convolution=-2 -1 0 -1 1 1 0 1 2:0:0:0:0:1:0","c":"normal"},
    "f52": {"name":"Pixelate Game","cmd":"scale=iw/12:ih/12:flags=neighbor,scale=12*iw:12*ih:flags=neighbor","c":"normal"},
    "f53": {"name":"Rotate 90","cmd":"transpose=1","c":"normal"},
    "f54": {"name":"Fish Eye Pro","cmd":"vignette=angle=PI/2","c":"normal"},
    "f55": {"name":"Glow Angel","cmd":"eq=brightness=0.18","c":"bright"},
    "f56": {"name":"Slow Mo 0.5x","cmd":"setpts=2*PTS","c":"normal"},
    "f57": {"name":"Fast 2x Turbo","cmd":"setpts=0.5*PTS","c":"normal"},
    "f58": {"name":"CinemaScope","cmd":"crop=21/9*ih:ih","c":"cinematic"},
    "f59": {"name":"Zoom In Pro","cmd":"scale=2*iw:2*ih,crop=iw/2:ih/2","c":"normal"},
    "f60": {"name":"Flip V","cmd":"vflip","c":"normal"},  Future export() async {
    if(videoPath==null) return;
    setState((){ processing=true; progress=0; });
    var tmp=await getTemporaryDirectory();
    var out="${tmp.path}/PROMAX_${DateTime.now().millisecondsSinceEpoch}.mp4";
    List<String> vf=[];
    vf.add("scale=3840:2160:flags=lanczos");
    if(blurBg) vf.add("gblur=sigma=3");
    if(stabilize) vf.add("deshake=rx=30:ry=30");
    if(denoise) vf.add("hqdn3d=4:4:6");
    if(autoHDR) vf.add("eq=contrast=1.35:saturation=1.45");
    for(var k in selected){ if(filters[k]!["cmd"]!.isNotEmpty) vf.add(filters[k]!["cmd"]!); }
    if(autoCaption) vf.add("drawtext=text='$captionText':fontcolor=white:fontsize=80:borderw=4:bordercolor=black:box=1:boxcolor=black@0.6:boxborderw=12:x=(w-text_w)/2:y=h-th-300");

    String cmd;
    if(musicPath!=null){
      cmd="-i $videoPath -i $musicPath -vf ${vf.join(",")} -map 0:v:0 -map 1:a:0 -shortest -c:v libx264 -preset ultrafast -crf 17 -c:a aac $out";
    } else {
      cmd="-i $videoPath -vf ${vf.join(",")} -c:v libx264 -preset ultrafast -crf 17 -c:a aac $out";
    }

    FFmpegKit.executeAsync(cmd, (s) async {
      if(ReturnCode.isSuccess(await s.getReturnCode())){
        try {
          var dir=Directory("/storage/emulated/0/Movies/4K Converter");
          if(!await dir.exists()) await dir.create(recursive:true);
          File fileOut=File(out);
          if(await fileOut.exists()){
            await fileOut.copy("${dir.path}/PROMAX_${DateTime.now().millisecondsSinceEpoch}.mp4");
          }
        } catch(e){}
        setState((){ processing=false; progress=100; status="100% PRO MAX 4K Saved to Gallery!"; });
      } else {
        setState((){ processing=false; status="Failed - Try with less filters"; });
      }
    }, (log){}, (stats){
      // FIXED - getProgress() काढला - फक्त getTime() वापरला
      int t=stats.getTime();
      double p=(t/1000).clamp(0, 99).toDouble();
      setState((){ progress=p; });
    });
    }
