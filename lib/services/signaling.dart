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
    'iceTransportPolicy': 'all',
    'rtcpMuxPolicy': 'require',
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
        debugPrint('[MEDIA] stream=${stream.id} localStreamHash=${stream.hashCode} track=${track.id} label=${track.label} enabled=${track.enabled} muted=${track.muted}');
      }

      if (!kIsWeb) {
        try {
          await Helper.setSpeakerphoneOn(true);
          debugPrint('[AUDIO_ROUTE] Helper.setSpeakerphoneOn(true) executed');
        } catch (e) {
          debugPrint('[AUDIO_ROUTE] Helper.setSpeakerphoneOn error: $e');
        }
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
          debugPrint('[MEDIA_FALLBACK] stream=${stream.id} track=${track.id} enabled=${track.enabled} muted=${track.muted}');
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
          debugPrint('[HANGUP_BEFORE] local track=${track.id} muted=${track.muted} enabled=${track.enabled}');
          track.enabled = false;
          track.stop();
          debugPrint('[HANGUP_AFTER] local track=${track.id} muted=${track.muted} enabled=${track.enabled}');
        } catch (_) {}
      }
      for (final track in remoteStream?.getTracks() ?? []) {
        try {
          debugPrint('[HANGUP_BEFORE] remote track=${track.id} muted=${track.muted} enabled=${track.enabled}');
          track.enabled = false;
          track.stop();
          debugPrint('[HANGUP_AFTER] remote track=${track.id} muted=${track.muted} enabled=${track.enabled}');
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
        debugPrint('📡 [ICE_FLUSHED] addCandidate SUCCESS: sdpMid=${candidate.sdpMid} sdpMLineIndex=${candidate.sdpMLineIndex} cand=${candidate.candidate}');
      } catch (e) {
        debugPrint('⚠️ [ICE_FLUSHED_ERROR] Error adding buffered candidate (${candidate.candidate}): $e');
      }
    }
    _pendingCandidates.clear();
  }

  /// Adds a candidate, buffering it if remote description isn't set yet.
  Future<void> _addIceCandidateSafe(RTCIceCandidate candidate) async {
    if (_remoteDescriptionSet && peerConnection != null) {
      try {
        await peerConnection!.addCandidate(candidate);
        debugPrint('📡 [ICE_ADDED] addCandidate SUCCESS: sdpMid=${candidate.sdpMid} sdpMLineIndex=${candidate.sdpMLineIndex} cand=${candidate.candidate}');
      } catch (e) {
        debugPrint('⚠️ [ICE_ADD_ERROR] Error adding candidate (${candidate.candidate}): $e');
      }
    } else {
      debugPrint('📡 [ICE_QUEUED] Queuing candidate (remote description not ready yet): sdpMid=${candidate.sdpMid} cand=${candidate.candidate}');
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

    try {
      final senders = await peerConnection?.getSenders() ?? [];
      for (final s in senders) {
        final tr = s.track;
        debugPrint('[CREATE_ROOM] pc=${peerConnection.hashCode} senders=${senders.length} audioTrack=${tr?.id} muted=${tr?.muted} enabled=${tr?.enabled}');
      }
    } catch (_) {}

    // ICE Candidate handler for Caller
    peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
      if (candidate == null || candidate.candidate == null) return;
      debugPrint('[ICE_GENERATED_LOCAL] caller sdpMid=${candidate.sdpMid} sdpMLineIndex=${candidate.sdpMLineIndex} candidate=${candidate.candidate}');
      try {
        await Supabase.instance.client.from('caller_candidates').insert({
          'room_id': roomId,
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid ?? '0',
          'sdpMLineIndex': candidate.sdpMLineIndex ?? 0,
          'sdpmid': candidate.sdpMid ?? '0',
          'sdpmlineindex': candidate.sdpMLineIndex ?? 0,
        });
        debugPrint('[ICE_STORED_DB] caller candidate inserted to DB successfully');
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
            final sdpMid = (candMap['sdpMid'] ?? candMap['sdpmid'] ?? '0').toString();
            final rawIndex = candMap['sdpMLineIndex'] ?? candMap['sdpmlineindex'];
            int sdpMLineIndex = 0;
            if (rawIndex is int) {
              sdpMLineIndex = rawIndex;
            } else if (rawIndex != null) {
              sdpMLineIndex = int.tryParse(rawIndex.toString()) ?? 0;
            }
            debugPrint('[ICE_RETRIEVED_DB] callee candidate from DB: sdpMid=$sdpMid sdpMLineIndex=$sdpMLineIndex candidate=$candidateStr');
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

    try {
      final receivers = await peerConnection?.getReceivers() ?? [];
      for (final r in receivers) {
        final tr = r.track;
        debugPrint('[JOIN_ROOM] pc=${peerConnection.hashCode} receivers=${receivers.length} audioTrack=${tr?.id} muted=${tr?.muted} enabled=${tr?.enabled}');
      }
    } catch (_) {}

    peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
      if (candidate == null || candidate.candidate == null) return;
      debugPrint('[ICE_GENERATED_LOCAL] callee sdpMid=${candidate.sdpMid} sdpMLineIndex=${candidate.sdpMLineIndex} candidate=${candidate.candidate}');
      try {
        await Supabase.instance.client.from('callee_candidates').insert({
          'room_id': joinRoomId,
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid ?? '0',
          'sdpMLineIndex': candidate.sdpMLineIndex ?? 0,
          'sdpmid': candidate.sdpMid ?? '0',
          'sdpmlineindex': candidate.sdpMLineIndex ?? 0,
        });
        debugPrint('[ICE_STORED_DB] callee candidate inserted to DB successfully');
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
            final sdpMid = (candMap['sdpMid'] ?? candMap['sdpmid'] ?? '0').toString();
            final rawIndex = candMap['sdpMLineIndex'] ?? candMap['sdpmlineindex'];
            int sdpMLineIndex = 0;
            if (rawIndex is int) {
              sdpMLineIndex = rawIndex;
            } else if (rawIndex != null) {
              sdpMLineIndex = int.tryParse(rawIndex.toString()) ?? 0;
            }
            debugPrint('[ICE_RETRIEVED_DB] caller candidate from DB: sdpMid=$sdpMid sdpMLineIndex=$sdpMLineIndex candidate=$candidateStr');
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
      debugPrint('[STATE] IceGatheringState: $state');
    };
    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('[STATE] ConnectionState: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _startStatsLogging();
      }
    };
    peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint('[STATE] SignalingState: $state');
    };
    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) async {
      debugPrint('[STATE] IceConnectionState: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _startStatsLogging();
        debugPrint('✅ [ICE] Media transport CONNECTED / COMPLETED!');
        try {
          final stats = await peerConnection?.getStats();
          for (final report in stats ?? []) {
            if (report.type == 'candidate-pair' &&
                (report.values['state'] == 'succeeded' || report.values['nominated'] == true)) {
              debugPrint(
                  '[ICE_SELECTED_PAIR] localCandidateId=${report.values['localCandidateId']} remoteCandidateId=${report.values['remoteCandidateId']} RTT=${report.values['currentRoundTripTime']} state=${report.values['state']}');
            }
          }
        } catch (_) {}
      }
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('⚠️ [ICE] Connection failed! Triggering restartIce()...');
        try {
          peerConnection?.restartIce();
        } catch (_) {}
      }
    };
    peerConnection?.onTrack = (RTCTrackEvent event) async {
      debugPrint('[REMOTE_TRACK] id=${event.track.id} kind=${event.track.kind} enabled=${event.track.enabled} muted=${event.track.muted} stream=${event.streams.isNotEmpty ? event.streams[0].id : "none"}');
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
      debugPrint('[REMOTE_STREAM_ADDED] streamId=${stream.id} tracks=${stream.getAudioTracks().length}');
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

  void _startStatsLogging() {
    Timer? statsTimer;
    statsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (peerConnection == null) {
        statsTimer?.cancel();
        return;
      }
      try {
        final stats = await peerConnection?.getStats();
        if (stats != null) {
          int packetsSent = 0;
          int packetsReceived = 0;
          int bytesSent = 0;
          int bytesReceived = 0;
          num currentRTT = 0;

          for (final report in stats) {
            final values = report.values;
            if (report.type == 'outbound-rtp' && (values['kind'] == 'audio' || values['mediaType'] == 'audio')) {
              packetsSent = values['packetsSent'] ?? 0;
              bytesSent = values['bytesSent'] ?? 0;
            }
            if (report.type == 'inbound-rtp' && (values['kind'] == 'audio' || values['mediaType'] == 'audio')) {
              packetsReceived = values['packetsReceived'] ?? 0;
              bytesReceived = values['bytesReceived'] ?? 0;
            }
            if (report.type == 'candidate-pair' && values['currentRoundTripTime'] != null) {
              currentRTT = values['currentRoundTripTime'];
            }
          }
          debugPrint('[WEBRTC_STATS] packetsSent=$packetsSent packetsReceived=$packetsReceived bytesSent=$bytesSent bytesReceived=$bytesReceived audioRTT=$currentRTT');
        }
      } catch (e) {
        debugPrint('[WEBRTC_STATS] Error fetching stats: $e');
      }
    });
    _activeTimers.add(statsTimer);
  }

  // Keep backward compat
  void registerPeerConnectionListeners() => _registerPeerConnectionListeners();
}
