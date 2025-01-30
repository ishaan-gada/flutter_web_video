import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraWithLoader extends StatelessWidget {
  static const route = '/camera-with-loader';

  const CameraWithLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CameraDescription>>(
        future: availableCameras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final frontCamera = snapshot.data!.firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.front,
                orElse: () => snapshot.data!.first,
              );
              return Center(
                child: ElevatedButton(
                  child: const Text('Start Recording'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraScreen(camera: frontCamera),
                      ),
                    );
                  },
                ),
              );
            } else {
              return const Center(child: Text('No cameras available'));
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;
  bool _isPaused = false;
  Timer? _timer;
  int _timeLeft = 10;
  int _elapsedTime = 0;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.max);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    if (_isRecording) {
      if (_isPaused) {
        await _controller.resumeVideoRecording();
        _startTimer();
      } else {
        await _controller.pauseVideoRecording();
        _timer?.cancel();
      }
      setState(() {
        _isPaused = !_isPaused;
      });
    } else {
      await _controller.startVideoRecording();
      _startTimer();
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _timeLeft = 10;
        _elapsedTime = 0;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          _elapsedTime++;
        } else {
          _stopRecording();
        }
      });
    });
  }

  void _stopRecording() async {
    if (!_isRecording) return;

    _timer?.cancel();
    try {
      XFile videoFile = await _controller.stopVideoRecording();

      // Convert XFile to Uint8List
      Uint8List bytes = await videoFile.readAsBytes();

      // Create Blob from bytes
      final blob = html.Blob([bytes], 'video/webm');

      // Create download link
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = 'recording_${DateTime.now().millisecondsSinceEpoch}.webm'
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void _discardAndReset() {
    _timer?.cancel();
    if (_isRecording) {
      _controller.stopVideoRecording();
    }
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _timeLeft = 10;
      _elapsedTime = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: CameraPreview(_controller),
                ),
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  onPressed: () {
                                    _discardAndReset();
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  'intro duce yourself ',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                )
                              ],
                            )),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                'Ensure you are in bright lit room ',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_isRecording || _isPaused)
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CircularProgressIndicator(
                                      value: _elapsedTime / 10,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _isPaused
                                              ? Colors.yellow
                                              : Colors.pink),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _toggleRecording,
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(20),
                                      backgroundColor: Colors.white,
                                      elevation: 5,
                                    ),
                                    child: const Icon(Icons.play_arrow,
                                        color: Colors.white),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _toggleRecording,
                                  child: Text(
                                    '$_timeLeft',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
