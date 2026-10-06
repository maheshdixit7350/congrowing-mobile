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

  final List<StreamSubscription> _activeSubs = [];

  // Track whether remote description has been set so we can buffer ICE
  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
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
      final stream = await navigator.mediaDevices.getUserMedia({
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
      });

      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
      }

      localVideo.srcObject = stream;
      localStream = stream;
    } catch (e) {
      debugPrint('Error acquiring media stream (mic/camera): $e');
      rethrow;
    }
  }

  // ── Hang up ────────────────────────────────────────────────────────────────

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    try {
      for (final sub in _activeSubs) {
        try {
          sub.cancel();
        } catch (_) {}
      }
      _activeSubs.clear();

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
  /// If [calleeUid] is empty, falls back to random matchmaking mode.
  Future<String> createRoom(bool isVideo, {String calleeUid = ''}) async {
    if (!supabaseInitialized) return '';

    _remoteDescriptionSet = false;
    _pendingCandidates.clear();

    final uid = SupabaseAuthService.instance.currentUser?.id;

    final insertPayload = {
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
          'sdpMid': candidate.sdpMid,
          'sdpmid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdpmlineindex': candidate.sdpMLineIndex,
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

    // Listen for SDP answer from callee
    final answerSub = Supabase.instance.client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId!)
        .listen((data) async {
          if (data.isNotEmpty) {
            final roomData = data.first;
            if (!_remoteDescriptionSet && roomData['answer'] != null) {
              final answerMap = Map<String, dynamic>.from(roomData['answer']);
              final answer = RTCSessionDescription(
                answerMap['sdp'],
                answerMap['type'],
              );
              try {
                await peerConnection?.setRemoteDescription(answer);
                _remoteDescriptionSet = true;
                await _flushPendingCandidates();
              } catch (e) {
                debugPrint('Error setting remote description: $e');
              }
            }
          }
        });
    _activeSubs.add(answerSub);

    // Listen for ICE candidates from callee
    final addedCalleeCandidates = <String>{};
    final calleeCandidateSub = Supabase.instance.client
        .from('callee_candidates')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId!)
        .listen((snapshot) {
          for (final candMap in snapshot) {
            final candidateStr = candMap['candidate'] as String?;
            if (candidateStr != null &&
                !addedCalleeCandidates.contains(candidateStr)) {
              addedCalleeCandidates.add(candidateStr);
              final sdpMid = (candMap['sdpMid'] ?? candMap['sdpmid']) as String?;
              final sdpMLineIndex = (candMap['sdpMLineIndex'] ?? candMap['sdpmlineindex']) as int?;
              _addIceCandidateSafe(
                RTCIceCandidate(
                  candidateStr,
                  sdpMid,
                  sdpMLineIndex,
                ),
              );
            }
          }
        });
    _activeSubs.add(calleeCandidateSub);

    return roomId!;
  }

  // ── Join Room (Callee) ─────────────────────────────────────────────────────

  Future<void> joinRoom(String joinRoomId) async {
    if (!supabaseInitialized) return;
    roomId = joinRoomId;

    _remoteDescriptionSet = false;
    _pendingCandidates.clear();

    final roomData = await Supabase.instance.client
        .from('rooms')
        .select()
        .eq('id', joinRoomId)
        .maybeSingle();
    if (roomData == null) return;

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
          'sdpMid': candidate.sdpMid,
          'sdpmid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdpmlineindex': candidate.sdpMLineIndex,
        });
      } catch (e) {
        debugPrint('Error sending callee ICE candidate: $e');
      }
    };

    // onTrack is already registered in _registerPeerConnectionListeners()

    final offerMap = Map<String, dynamic>.from(roomData['offer']);
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(offerMap['sdp'], offerMap['type']),
    );
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();

    final answerConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': 'true',
        'OfferToReceiveVideo': 'true',
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

    // Listen for ICE candidates from caller
    final addedCallerCandidates = <String>{};
    final callerCandidateSub = Supabase.instance.client
        .from('caller_candidates')
        .stream(primaryKey: ['id'])
        .eq('room_id', joinRoomId)
        .listen((snapshot) {
          for (final candMap in snapshot) {
            final candidateStr = candMap['candidate'] as String?;
            if (candidateStr != null &&
                !addedCallerCandidates.contains(candidateStr)) {
              addedCallerCandidates.add(candidateStr);
              final sdpMid = (candMap['sdpMid'] ?? candMap['sdpmid']) as String?;
              final sdpMLineIndex = (candMap['sdpMLineIndex'] ?? candMap['sdpmlineindex']) as int?;
              _addIceCandidateSafe(
                RTCIceCandidate(
                  candidateStr,
                  sdpMid,
                  sdpMLineIndex,
                ),
              );
            }
          }
        });
    _activeSubs.add(callerCandidateSub);
  }

  // ── Incoming Call Listener ────────────────────────────────────────────────

  /// Listens for incoming calls where [myUid] is the callee.
  /// Calls [onIncomingCall] with (roomId, callType, callerId) when found.
  /// Returns the subscription so callers can cancel it.
  StreamSubscription listenForIncomingCall(
      String myUid, IncomingCallCallback onIncomingCall) {
    final sub = Supabase.instance.client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('callee_id', myUid)
        .listen((data) {
          for (final row in data) {
            final status = row['status'] as String? ?? '';
            final rid = row['id'].toString();
            final callType = row['type'] as String? ?? 'video';
            final callerId = row['caller_id'] as String? ?? '';
            onIncomingCall(rid, callType, callerId, status);
          }
        });
    return sub;
  }

  /// Listen for room updates (e.g. status changes like 'ended')
  StreamSubscription listenToRoomStatus(
      String targetRoomId, void Function(String status) onStatusChanged) {
    return Supabase.instance.client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('id', targetRoomId)
        .listen((snapshot) {
          if (snapshot.isNotEmpty) {
            final status = snapshot.first['status'] as String? ?? '';
            onStatusChanged(status);
          }
        });
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
