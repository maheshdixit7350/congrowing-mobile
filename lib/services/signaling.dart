import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';

typedef StreamStateCallback = void Function(MediaStream stream);
typedef IncomingCallCallback = void Function(
    String roomId, String callType, String callerId, String status);

class Signaling {
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
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      },
      {
        'urls': 'stun:stun.relay.metered.ca:80',
      },
      {
        'urls': 'turn:global.relay.metered.ca:80',
        'username': 'e05c4a4a1347fef5fedaa1c5',
        'credential': 'fCBVVCuN/6gVZrFj',
      },
      {
        'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
        'username': 'e05c4a4a1347fef5fedaa1c5',
        'credential': 'fCBVVCuN/6gVZrFj',
      },
      {
        'urls': 'turn:global.relay.metered.ca:443',
        'username': 'e05c4a4a1347fef5fedaa1c5',
        'credential': 'fCBVVCuN/6gVZrFj',
      },
      {
        'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
        'username': 'e05c4a4a1347fef5fedaa1c5',
        'credential': 'fCBVVCuN/6gVZrFj',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  // ── Media ──────────────────────────────────────────────────────────────────

  Future<void> openUserMedia(
      RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo,
      {bool isVideo = true}) async {
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
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

      localVideo.srcObject = stream;
      localStream = stream;
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

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    try {
      for (final timer in _activeTimers) {
        try {
          timer.cancel();
        } catch (_) {}
      }
      _activeTimers.clear();

      final tracks = localVideo.srcObject?.getTracks() ?? [];
      for (final track in tracks) {
        track.stop();
      }

      localStream?.getTracks().forEach((track) => track.stop());
      remoteStream?.getTracks().forEach((track) => track.stop());

      localStream?.dispose();
      remoteStream?.dispose();

      if (roomId != null && supabaseInitialized) {
        await Supabase.instance.client.from('rooms').update({
          'status': 'ended',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', roomId!);
      }
    } catch (e) {
      debugPrint('Error during hangup: $e');
    } finally {
      peerConnection?.close();
      peerConnection = null;
      localStream = null;
      remoteStream = null;
      roomId = null;
      _remoteDescriptionSet = false;
      _pendingCandidates.clear();
    }
  }

  // ── Flush buffered ICE candidates ─────────────────────────────────────────

  Future<void> _flushPendingCandidates() async {
    for (final candidate in _pendingCandidates) {
      try {
        await peerConnection?.addCandidate(candidate);
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
      } catch (e) {
        debugPrint('Error adding ICE candidate: $e');
      }
    } else {
      _pendingCandidates.add(candidate);
    }
  }

  // ── Create Room (Caller) ───────────────────────────────────────────────────

  /// Creates a WebRTC room targeting a specific [calleeUid].
  Future<String> createRoom(bool isVideo, {String calleeUid = ''}) async {
    if (!supabaseInitialized) return '';

    _remoteDescriptionSet = false;
    _pendingCandidates.clear();

    final uid = SupabaseAuthService.instance.currentUser?.id;

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
    peerConnection = await createPeerConnection(configuration);

    _registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

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

    final offerConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': 'true',
        'OfferToReceiveVideo': isVideo ? 'true' : 'false',
      },
      'optional': [],
    };

    final offer = await peerConnection!.createOffer(offerConstraints);
    await peerConnection!.setLocalDescription(offer);

    await Supabase.instance.client.from('rooms').update({
      'offer': offer.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId!);

    // Periodic 500ms REST polling for SDP answer from callee
    Timer? answerTimer;
    answerTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
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

    // Periodic 500ms REST polling for Callee ICE candidates
    final addedCalleeCandidates = <String>{};
    Timer? calleeCandidateTimer;
    calleeCandidateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
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
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (roomData == null || roomData['offer'] == null) {
      debugPrint('Room or offer not found for room $joinRoomId');
      return;
    }

    final isRoomVideo = roomData['type'] == 'video';

    peerConnection = await createPeerConnection(configuration);
    _registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

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

    final answerConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': 'true',
        'OfferToReceiveVideo': isRoomVideo ? 'true' : 'false',
      },
      'optional': [],
    };

    final answer = await peerConnection!.createAnswer(answerConstraints);
    await peerConnection!.setLocalDescription(answer);

    await Supabase.instance.client.from('rooms').update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'connected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', joinRoomId);

    // Periodic 500ms REST polling for Caller ICE candidates
    final addedCallerCandidates = <String>{};
    Timer? callerCandidateTimer;
    callerCandidateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
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
        final data = await Supabase.instance.client
            .from('rooms')
            .select()
            .eq('callee_id', myUid)
            .order('created_at', ascending: false)
            .limit(5);

        for (final row in data) {
          final status = row['status'] as String? ?? '';
          final rid = row['id'].toString();
          final callType = row['type'] as String? ?? 'video';
          final callerId = row['caller_id'] as String? ?? '';
          onIncomingCall(rid, callType, callerId, status);
        }
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
      debugPrint('ICE gathering state: $state');
    };
    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('Peer connection state: $state');
    };
    peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint('Signaling state: $state');
    };
    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('ICE connection state: $state');
    };
    peerConnection?.onTrack = (RTCTrackEvent event) async {
      event.track.enabled = true;
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
      } else {
        remoteStream ??= await createLocalMediaStream('remote_stream');
        remoteStream?.addTrack(event.track);
      }
      for (final track in remoteStream?.getAudioTracks() ?? []) {
        track.enabled = true;
      }
      if (remoteStream != null) {
        onAddRemoteStream?.call(remoteStream!);
      }
    };
    peerConnection?.onAddStream = (MediaStream stream) {
      remoteStream = stream;
      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
      }
      onAddRemoteStream?.call(remoteStream!);
    };
  }

  // Keep backward compat
  void registerPeerConnectionListeners() => _registerPeerConnectionListeners();
}
