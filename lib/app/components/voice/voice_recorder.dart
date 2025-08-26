import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef SpeechResultCallback = void Function(String);

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({
    super.key,
    required this.recorderController,
    required this.textFieldSize,
    required this.iOS,
    required this.samsung,
  });

  final RecorderController recorderController;
  final Size textFieldSize;
  final bool iOS;
  final bool samsung;

  static Future<void> Function(SpeechResultCallback) startTranscription = _startTranscription;
  static Future<String> Function() stopTranscription = _stopTranscription;
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static String _lastWords = '';

  static Future<void> _startTranscription(SpeechResultCallback onResult) async {
    _lastWords = '';
    if (await _speech.initialize()) {
      await _speech.listen(onResult: (res) {
        _lastWords = res.recognizedWords;
        onResult(_lastWords);
      });
    }
  }

  static Future<String> _stopTranscription() async {
    await _speech.stop();
    return _lastWords;
  }

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  late final Stream<Duration> _recordingStream;

  @override
  void initState() {
    super.initState();
    _recordingStream = widget.recorderController.onCurrentDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 1),
      child: Row(
        children: [
          AudioWaveforms(
            size: Size(
              widget.textFieldSize.width - _getWidth(widget.iOS, widget.samsung),
              widget.textFieldSize.height - 15,
            ),
            recorderController: widget.recorderController,
            padding: EdgeInsets.symmetric(
              vertical: 5,
              horizontal: widget.iOS ? 10 : 15,
            ),
            waveStyle: WaveStyle(
              waveColor: widget.iOS
                  ? context.theme.colorScheme.primary
                  : context.theme.colorScheme.properOnSurface,
              waveCap: StrokeCap.square,
              spacing: 4.0,
              showBottom: true,
              extendWaveform: true,
              showMiddleLine: false,
            ),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(
                  color: widget.iOS
                      ? Colors.transparent
                      : context.theme.colorScheme.outline,
                  width: 1,
                ),
              ),
              borderRadius: BorderRadius.circular(20),
              color: widget.iOS
                  ? Colors.transparent
                  : context.theme.colorScheme.properSurface,
            ),
          ),
          Visibility(
            visible: widget.iOS,
            child: Center(
              child: StreamBuilder<Duration>(
                stream: _recordingStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final minutes = snapshot.data!.inMinutes;
                    final seconds =
                        (snapshot.data!.inSeconds % 60).toString().padLeft(2, '0');
                    return Text(
                      '$minutes:$seconds',
                      style: TextStyle(
                        color: context.theme.colorScheme.primary,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getWidth(bool iOS, bool samsung) {
    if (samsung) {
      return 0;
    } else if (iOS) {
      return 105;
    }
    return 80;
  }
}
