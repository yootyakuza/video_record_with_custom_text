import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:test_video/assets.dart';
import 'package:test_video/enum.dart';
import 'package:test_video/video_page.dart';

import 'enum.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isVisible = true;

  late CameraController _cameraController;
  MessageRecordState messageRecordState = MessageRecordState.none;
  String text = "หันซ้าย";
  late Timer _timer;

  void intervalTime() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      switch (messageRecordState) {
        case MessageRecordState.none:
          text = "หันขวา";
          messageRecordState = MessageRecordState.step1;

          break;
        case MessageRecordState.step1:
          text = "หน้าตรง";
          messageRecordState = MessageRecordState.step2;
          break;
        default:
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(front, ResolutionPreset.max);
    await _cameraController.initialize();
    intervalTime();
    setState(() => _isLoading = false);
  }

  _recordVideo() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() => _isRecording = false);
      final route = MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoPage(filePath: file.path),
      );
      Navigator.push(context, route);
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      setState(() {
        // _timer.cancel();
        messageRecordState = MessageRecordState.none;
        _isVisible = false;
        _isRecording = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CameraPreview(_cameraController),
                Visibility(
                  visible: _isVisible,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.black26,
                      child: Column(
                        children: <Widget>[
                          Text(text,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w400)),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Lottie.asset(
                              messageRecordState == MessageRecordState.none
                                  ? Assets.lookLeft
                                  : messageRecordState ==
                                          MessageRecordState.step1
                                      ? Assets.lookRight
                                      : Assets.face,
                              fit: BoxFit.cover,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: FloatingActionButton(
                    backgroundColor: Colors.red,
                    child: Icon(_isRecording ? Icons.stop : Icons.circle),
                    onPressed: () => _recordVideo(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
