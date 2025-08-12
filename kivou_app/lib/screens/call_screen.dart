import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kivou_app/services/webrtc_signaling.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  final String roomId;
  final bool video;
  final String signalingUrl; // ex: wss://fidest.ci/kivou/backend/ws
  const CallScreen(
      {super.key,
      required this.roomId,
      required this.video,
      required this.signalingUrl});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  bool _micOn = true;
  bool _camOn = true;
  late final WebRtcSignalingClient _signal;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Permissions runtime (Android 6+)
    final mic = await Permission.microphone.request();
    final cam = widget.video
        ? await Permission.camera.request()
        : PermissionStatus.granted;
    if (!mic.isGranted || !cam.isGranted) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };
    _pc = await createPeerConnection(config);
    _pc!.onIceCandidate = (c) {
      if (c.candidate != null) {
        _signal.send({
          'type': 'ice',
          'room': widget.roomId,
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        });
      }
    };
    _pc!.onTrack = (e) {
      if (e.streams.isNotEmpty) {
        setState(() => _remoteRenderer.srcObject = e.streams[0]);
      }
    };

    final mediaConstraints = {
      'audio': true,
      'video': widget.video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 15}
            }
          : false
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    for (var track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }
    _localRenderer.srcObject = _localStream;

    _signal = WebRtcSignalingClient(widget.signalingUrl);
    _signal.onMessage = _onSignal;
    await _signal.connect();
    _signal.join(widget.roomId, 'me');

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    _signal.send({
      'type': 'offer',
      'room': widget.roomId,
      'sdp': offer.sdp,
    });
  }

  void _onSignal(Map<String, dynamic> msg) async {
    switch (msg['type']) {
      case 'offer':
        final desc = RTCSessionDescription(msg['sdp'] as String, 'offer');
        await _pc!.setRemoteDescription(desc);
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        _signal
            .send({'type': 'answer', 'room': widget.roomId, 'sdp': answer.sdp});
        break;
      case 'answer':
        final desc = RTCSessionDescription(msg['sdp'] as String, 'answer');
        await _pc!.setRemoteDescription(desc);
        break;
      case 'ice':
        final cand = RTCIceCandidate(
          msg['candidate'] as String,
          msg['sdpMid'] as String?,
          msg['sdpMLineIndex'] as int?,
        );
        await _pc!.addCandidate(cand);
        break;
    }
  }

  @override
  void dispose() {
    _signal.close();
    _pc?.close();
    _localStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(_remoteRenderer)
                  : Center(
                      child: Icon(Icons.person_outline,
                          size: 120, color: Colors.white24),
                    ),
            ),
            Positioned(
              right: 16,
              bottom: 120,
              child: SizedBox(
                width: 120,
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(_localRenderer, mirror: true),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _circle(
                      icon: _micOn ? Icons.mic : Icons.mic_off,
                      color: _micOn
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.error,
                      onTap: () {
                        setState(() => _micOn = !_micOn);
                        _localStream
                            ?.getAudioTracks()
                            .forEach((t) => t.enabled = _micOn);
                      },
                    ),
                    const SizedBox(width: 16),
                    if (widget.video)
                      _circle(
                        icon: _camOn ? Icons.videocam : Icons.videocam_off,
                        color: _camOn
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                        onTap: () {
                          setState(() => _camOn = !_camOn);
                          _localStream
                              ?.getVideoTracks()
                              .forEach((t) => t.enabled = _camOn);
                        },
                      ),
                    const SizedBox(width: 16),
                    _circle(
                      icon: Icons.call_end,
                      color: theme.colorScheme.error,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _circle(
      {required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: CircleAvatar(
        radius: 32,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
