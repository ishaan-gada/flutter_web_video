import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:record_web_video/video_player.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  XFile? _video;
  int _timer = 0;
  String status = "";
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);
    print(firstCamera);
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    await _controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future<void> _startVideoRecording() async {
    if (!_controller!.value.isInitialized) {
      return null;
    }

    await _controller!.startVideoRecording();
    setState(() {
      status = "recording started";
    });
    for (int i = 0; i < 11; i++) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _timer = i;
        status = "recording $_timer";
      });
    }
    final XFile file = await _controller!.stopVideoRecording();
    setState(() {
      _video = file;
      status = "recording stopped";
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoFile: _video!),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    setState(() {});
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Camera Example')),
        body: _controller == null
            ? const Center(child: CircularProgressIndicator())
            : CameraPreview(
                _controller!,
                child: Center(
                  child: Text(
                    "$_timer",
                    style: TextStyle(fontSize: 34, color: Colors.black),
                  ),
                ),
              ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Status : $status"),
            FloatingActionButton(
              heroTag: 'btn1',
              child: const Icon(Icons.videocam),
              onPressed: _startVideoRecording,
            ),
          ],
        ));
  }
}
