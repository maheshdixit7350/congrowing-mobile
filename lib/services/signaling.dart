import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';

import 'package:permission_handler/permission_handler.dart';

typedef StreamStateCallback = void Function(MediaStream stream);
typedef IncomingCallCallback = void Function(
    String roomId, String callType, String callerId, String status);

class Signaling {
  static String? activeCallRoomId;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;

  StreamStateCallback? onAddRemoteStream;

  final List<Timer> _activeTimers = [];
  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
          'stun:openrelay.metered.ca:80',
          'stun:openrelay.metered.ca:443',
        ]
      },
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp',
          'turns:openrelay.metered.ca:443?transport=tcp',
        ],
        'username': 'openrelay',
        'credential': 'openrelay',
      },
      {
        'urls': [
          'turn:global.relay.metered.ca:80',
          'turn:global.relay.metered.ca:80?transport=tcp',
          'turn:global.relay.metered.ca:443',
          'turns:global.relay.metered.ca:443?transport=tcp',
        ],
        'username': 'e05c4a4a1347fef5fedaa1c5',
        'credential': 'fCBVVCuN/6gVZrFj',
      },
    ],
    'iceCandidatePoolSize': 10,
    'sdpSemantics': 'unified-plan',
  };

  // ── Media ──────────────────────────────────────────────────────────────────

  Future<void> openUserMedia(
      RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo,
      {bool isVideo = true}) async {
    if (localStream != null) {
      try {
        for (final track in localStream!.getTracks()) {
          track.enabled = false;
          track.stop();
        }
        await localStream!.dispose();
      } catch (_) {}
      localStream = null;
    }

    if (!kIsWeb) {
      try {
        await Permission.microphone.request();
        if (isVideo) {
          await Permission.camera.request();
        }
      } catch (e) {
        debugPrint('Runtime permission error: $e');
      }
    }

    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
              }
            : false,
      };

      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
      }

      if (!kIsWeb) {
        try {
          await Helper.setSpeakerphoneOn(true);
        } catch (_) {}
      }

      localVideo.srcObject = stream;
      localStream = stream;
      debugPrint('[Signaling] Fresh hardware media stream acquired.');
    } catch (e) {
      debugPrint('Error acquiring media stream (mic/camera): $e');
      try {
        final stream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': isVideo,
        });
        for (final track in stream.getAudioTracks()) {
          track.enabled = true;
        }
        localVideo.srcObject = stream;
        localStream = stream;
      } catch (err) {
        debugPrint('Fallback getUserMedia failed: $err');
        rethrow;
      }
    }
  }

  // ── Hang up ────────────────────────────────────────────────────────────────

  Future<void> hangUp(RTCVideoRenderer? localVideo, [RTCVideoRenderer? remoteVideo]) async {
    try {
      for (final timer in _activeTimers) {
        try {
          timer.cancel();
        } catch (_) {}
      }
      _activeTimers.clear();

      for (final track in localStream?.getTracks() ?? []) {
        try {
          track.enabled = false;
          track.stop();
        } catch (_) {}
      }
      for (final track in remoteStream?.getTracks() ?? []) {
        try {
          track.enabled = false;
          track.stop();
        } catch (_) {}
      }

      if (localVideo != null) {
        try {
          localVideo.srcObject = null;
        } catch (_) {}
      }
      if (remoteVideo != null) {
        try {
          remoteVideo.srcObject = null;
        } catch (_) {}
      }

      try {
        await localStream?.dispose();
      } catch (_) {}
      try {
        await remoteStream?.dispose();
      } catch (_) {}

      if (roomId != null && supabaseInitialized) {
        final currentRoomId = roomId!;
        await Supabase.instance.client.from('rooms').update({
          'status': 'ended',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentRoomId);

        try {
          await Supabase.instance.client
              .from('caller_candidates')
              .delete()
              .eq('room_id', currentRoomId);
          await Supabase.instance.client
              .from('callee_candidates')
              .delete()
              .eq('room_id', currentRoomId);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error during hangup: $e');
    } finally {
      try {
        await peerConnection?.close();
        await peerConnection?.dispose();
      } catch (_) {}
      peerConnection = null;
      localStream = null;
      remoteStream = null;
      roomId = null;
      Signaling.activeCallRoomId = null;
      _remoteDescriptionSet = false;
      _pendingCandidates.clear();
      debugPrint('[Signaling] PeerConnection and media tracks completely disposed.');
    }
  }

  // ── Flush buffered ICE candidates ─────────────────────────────────────────

  Future<void> _flushPendingCandidates() async {
    if (peerConnection == null) return;
    debugPrint('📡 Flushing ${_pendingCandidates.length} queued ICE candidates...');
    for (final candidate in List.of(_pendingCandidates)) {
      try {
        await peerConnection?.addCandidate(candidate);
        debugPrint('📡 Flushed ICE candidate successfully');
      } catch (e) {
        debugPrint('Error adding buffered ICE candidate: $e');
      }
    }
    _pendingCandidates.clear();
  }

  /// Adds a candidate, buffering it if remote description isn't set yet.
  Future<void> _addIceCandidateSafe(RTCIceCandidate candidate) async {
    if (_remoteDescriptionSet && peerConnection != null) {
      try {
        await peerConnection!.addCandidate(candidate);
        debugPrint('📡 Added WebRTC ICE candidate successfully');
      } catch (e) {
        debugPrint('Error adding ICE candidate: $e');
      }
    } else {
      debugPrint('📡 Queuing ICE candidate (remote description not ready yet)');
      _pendingCandidates.add(candidate);
    }
  }

  // ── Setup Transceivers for 2-Way Audio ─────────────────────────────────────

  Future<void> _setupTransceivers() async {
    if (peerConnection == null) return;
    try {
      final transceivers = await peerConnection!.getTransceivers();
      for (final tr in transceivers) {
        await tr.setDirection(TransceiverDirection.SendRecv);
      }
    } catch (e) {
      debugPrint('Transceiver setup warning: $e');
    }
  }

  // ── Create Room (Caller) ───────────────────────────────────────────────────

  /// Creates a WebRTC room targeting a specific [calleeUid].
  Future<String> createRoom(bool isVideo, {String calleeUid = ''}) async {
    if (!supabaseInitialized) return '';

    _remoteDescriptionSet = false;
    _pendingCandidates.clear();

    final uid = SupabaseAuthService.instance.currentUser?.id;

    if (uid != null) {
      try {
        await Supabase.instance.client
            .from('rooms')
            .update({
              'status': 'ended',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('caller_id', uid)
            .inFilter('status', ['waiting', 'ringing']);
      } catch (e) {
        debugPrint('Warning cleaning stale caller rooms: $e');
      }
    }

    final insertPayload = <String, dynamic>{
      'type': isVideo ? 'video' : 'voice',
      'status': calleeUid.isNotEmpty ? 'ringing' : 'waiting',
      'caller_id': uid,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (calleeUid.isNotEmpty) {
      insertPayload['callee_id'] = calleeUid;
    }

    final room = await Supabase.instance.client
        .from('rooms')
        .insert(insertPayload)
        .select()
        .single();

    roomId = room['id'].toString();
    Signaling.activeCallRoomId = roomId;

    if (peerConnection != null) {
      try {
        await peerConnection?.close();
        await peerConnection?.dispose();
      } catch (_) {}
      peerConnection = null;
    }

    peerConnection = await createPeerConnection(configuration);

    _registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    await _setupTransceivers();

    // ICE Candidate handler for Caller
    peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
      if (candidate == null || candidate.candidate == null) return;
      try {
        await Supabase.instance.client.from('caller_candidates').insert({
          'room_id': roomId,
          'candidate': candidate.candidate,
          'sdpmid': candidate.sdpMid ?? '0',
          'sdpmlineindex': candidate.sdpMLineIndex ?? 0,
        });
      } catch (e) {
        debugPrint('Error sending caller ICE candidate: $e');
      }
    };

    final offer = await peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await peerConnection!.setLocalDescription(offer);

    await Supabase.instance.client.from('rooms').update({
      'offer': offer.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId!);

    // Fast 300ms REST polling for SDP answer from callee
    Timer? answerTimer;
    answerTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (_remoteDescriptionSet || peerConnection == null || roomId == null) {
        answerTimer?.cancel();
        return;
      }
      try {
        final res = await Supabase.instance.client
            .from('rooms')
            .select('answer')
            .eq('id', roomId!)
            .maybeSingle();
        if (res != null && res['answer'] != null && !_remoteDescriptionSet) {
          final answerMap = Map<String, dynamic>.from(res['answer']);
          final answer = RTCSessionDescription(answerMap['sdp'], answerMap['type']);
          await peerConnection?.setRemoteDescription(answer);
          _remoteDescriptionSet = true;
          await _flushPendingCandidates();
          answerTimer?.cancel();
        }
      } catch (e) {
        debugPrint('Error polling answer: $e');
      }
    });
    _activeTimers.add(answerTimer);

    // Fast 300ms REST polling for Callee ICE candidates
    final addedCalleeCandidates = <String>{};
    Timer? calleeCandidateTimer;
    calleeCandidateTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (roomId == null || peerConnection == null) {
        calleeCandidateTimer?.cancel();
        return;
      }
      try {
        final list = await Supabase.instance.client
            .from('callee_candidates')
            .select()
            .eq('room_id', roomId!);
        for (final candMap in list) {
          final candidateStr = candMap['candidate'] as String?;
          if (candidateStr != null && !addedCalleeCandidates.contains(candidateStr)) {
            addedCalleeCandidates.add(candidateStr);
            final sdpMid = (candMap['sdpMid'] ?? candMap['sdpmid'])?.toString();
            final rawIndex = candMap['sdpMLineIndex'] ?? candMap['sdpmlineindex'];
            int? sdpMLineIndex;
            if (rawIndex is int) {
              sdpMLineIndex = rawIndex;
            } else if (rawIndex != null) {
              sdpMLineIndex = int.tryParse(rawIndex.toString());
            }
            await _addIceCandidateSafe(RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex));
          }
        }
      } catch (e) {
        debugPrint('Error polling callee ICE candidates: $e');
      }
    });
    _activeTimers.add(calleeCandidateTimer);

    return roomId!;
  }

  // ── Join Room (Callee) ─────────────────────────────────────────────────────

  Future<void> joinRoom(String joinRoomId) async {
    if (!supabaseInitialized) return;
    roomId = joinRoomId;
    Signaling.activeCallRoomId = joinRoomId;

    _remoteDescriptionSet = false;
    _pendingCandidates.clear();

    // Poll for offer in rooms table up to 10s to eliminate race condition
    Map<String, dynamic>? roomData;
    for (int i = 0; i < 20; i++) {
      final res = await Supabase.instance.client
          .from('rooms')
          .select()
          .eq('id', joinRoomId)
          .maybeSingle();
      if (res != null && res['offer'] != null) {
        roomData = res;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (roomData == null || roomData['offer'] == null) {
      debugPrint('Room or offer not found for room $joinRoomId');
      return;
    }

    final isRoomVideo = roomData['type'] == 'video';

    if (peerConnection != null) {
      try {
        await peerConnection?.close();
        await peerConnection?.dispose();
      } catch (_) {}
      peerConnection = null;
    }

    peerConnection = await createPeerConnection(configuration);
    _registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    await _setupTransceivers();

    peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
      if (candidate == null || candidate.candidate == null) return;
      try {
        await Supabase.instance.client.from('callee_candidates').insert({
          'room_id': joinRoomId,
          'candidate': candidate.candidate,
          'sdpmid': candidate.sdpMid ?? '0',
          'sdpmlineindex': candidate.sdpMLineIndex ?? 0,
        });
      } catch (e) {
        debugPrint('Error sending callee ICE candidate: $e');
      }
    };

    final offerMap = Map<String, dynamic>.from(roomData['offer']);
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(offerMap['sdp'], offerMap['type']),
    );
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();

    final answer = await peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isRoomVideo,
    });
    await peerConnection!.setLocalDescription(answer);

    await Supabase.instance.client.from('rooms').update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'connected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', joinRoomId);

    // Fast 300ms REST polling for Caller ICE candidates
    final addedCallerCandidates = <String>{};
    Timer? callerCandidateTimer;
    callerCandidateTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (roomId == null || peerConnection == null) {
        callerCandidateTimer?.cancel();
        return;
      }
      try {
        final list = await Supabase.instance.client
            .from('caller_candidates')
            .select()
            .eq('room_id', joinRoomId);
        for (final candMap in list) {
          final candidateStr = candMap['candidate'] as String?;
          if (candidateStr != null && !addedCallerCandidates.contains(candidateStr)) {
            addedCallerCandidates.add(candidateStr);
            final sdpMid = (candMap['sdpMid'] ?? candMap['sdpmid'])?.toString();
            final rawIndex = candMap['sdpMLineIndex'] ?? candMap['sdpmlineindex'];
            int? sdpMLineIndex;
            if (rawIndex is int) {
              sdpMLineIndex = rawIndex;
            } else if (rawIndex != null) {
              sdpMLineIndex = int.tryParse(rawIndex.toString());
            }
            await _addIceCandidateSafe(RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex));
          }
        }
      } catch (e) {
        debugPrint('Error polling caller ICE candidates: $e');
      }
    });
    _activeTimers.add(callerCandidateTimer);
  }

  // ── Incoming Call Listener ────────────────────────────────────────────────

  StreamSubscription listenForIncomingCall(
      String myUid, IncomingCallCallback onIncomingCall) {
    final controller = StreamController<dynamic>();

    Timer? timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!supabaseInitialized) return;
      try {
        final thirtyFiveSecsAgo = DateTime.now()
            .subtract(const Duration(seconds: 35))
            .toIso8601String();

        final data = await Supabase.instance.client
            .from('rooms')
            .select()
            .eq('callee_id', myUid)
            .gte('created_at', thirtyFiveSecsAgo)
            .order('created_at', ascending: false)
            .limit(5);

        for (final row in data) {
          final status = row['status'] as String? ?? '';
          final rid = row['id'].toString();
          final callType = row['type'] as String? ?? 'video';
          final callerId = row['caller_id'] as String? ?? '';
          onIncomingCall(rid, callType, callerId, status);
        }

        try {
          await Supabase.instance.client
              .from('rooms')
              .update({
                'status': 'ended',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('callee_id', myUid)
              .lt('created_at', thirtyFiveSecsAgo)
              .eq('status', 'ringing');
        } catch (_) {}
      } catch (_) {}
    });

    controller.onCancel = () {
      timer?.cancel();
      controller.close();
    };

    return controller.stream.listen((_) {});
  }

  /// Listen for room updates (e.g. status changes like 'ended')
  StreamSubscription listenToRoomStatus(
      String targetRoomId, void Function(String status) onStatusChanged) {
    final controller = StreamController<dynamic>();

    Timer? timer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!supabaseInitialized) return;
      try {
        final snapshot = await Supabase.instance.client
            .from('rooms')
            .select('status')
            .eq('id', targetRoomId);

        if (snapshot.isNotEmpty) {
          final status = snapshot.first['status'] as String? ?? '';
          onStatusChanged(status);
        }
      } catch (_) {}
    });

    controller.onCancel = () {
      timer?.cancel();
      controller.close();
    };

    return controller.stream.listen((_) {});
  }

  // ── Peer Connection Listeners ─────────────────────────────────────────────

  void _registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('[Signaling] ICE gathering state: $state');
    };
    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('[Signaling] Peer connection state: $state');
    };
    peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint('[Signaling] Signaling state: $state');
    };
    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('[Signaling] ICE connection state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('⚠️ [Signaling] ICE connection failed. Restarting ICE...');
        try {
          peerConnection?.restartIce();
        } catch (_) {}
      }
    };
    peerConnection?.onTrack = (RTCTrackEvent event) async {
      debugPrint('🎙️ Remote track received: ${event.track.kind}');
      event.track.enabled = true;
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
      } else {
        remoteStream ??= await createLocalMediaStream('remote_stream');
        remoteStream?.addTrack(event.track);
      }
      for (final track in remoteStream?.getAudioTracks() ?? []) {
        track.enabled = true;
        try {
          Helper.setVolume(1.0, track);
        } catch (_) {}
      }
      try {
        if (!kIsWeb) {
          for (final track in localStream?.getAudioTracks() ?? []) {
            track.enabled = true;
          }
          Helper.setSpeakerphoneOn(true);
        }
      } catch (_) {}
      if (remoteStream != null) {
        onAddRemoteStream?.call(remoteStream!);
      }
    };
    peerConnection?.onAddStream = (MediaStream stream) {
      debugPrint('🎙️ Remote stream added');
      remoteStream = stream;
      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
        try {
          Helper.setVolume(1.0, track);
        } catch (_) {}
      }
      try {
        if (!kIsWeb) {
          for (final track in localStream?.getAudioTracks() ?? []) {
            track.enabled = true;
          }
          Helper.setSpeakerphoneOn(true);
        }
      } catch (_) {}
      onAddRemoteStream?.call(remoteStream!);
    };
  }

  // Keep backward compat
  void registerPeerConnectionListeners() => _registerPeerConnectionListeners();
}
