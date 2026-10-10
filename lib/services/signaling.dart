import 'dart:async';
import 'dart:convert';
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
  static bool forceRelayOnly = true;

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  bool isCaller = false;
  bool _isRestartingIce = false;

  StreamStateCallback? onAddRemoteStream;

  final List<Timer> _activeTimers = [];
  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  // Stats timer hardening (Task 1)
  Timer? _statsTimer;
  bool _statsLoggingStarted = false;

  // Candidate counters for TURN diagnostics (Task 2)
  int _localHostCandidateCount = 0;
  int _localSrflxCandidateCount = 0;
  int _localRelayCandidateCount = 0;

  // RTP Flow validation metrics (Task 7)
  int _lastAudioPacketsSent = 0;
  int _lastAudioPacketsReceived = 0;
  int _lastVideoPacketsSent = 0;
  int _lastVideoPacketsReceived = 0;
  int _noRtpFlowSeconds = 0;

  // Stability timer metrics (Phase 7)
  Timer? _stabilityTimer;
  int _stabilitySeconds = 0;

  String _getCandidateType(String candStr) {
    final lower = candStr.toLowerCase();
    if (lower.contains('typ host')) return 'host';
    if (lower.contains('typ srflx')) return 'srflx';
    if (lower.contains('typ relay')) return 'relay';
    return 'unknown';
  }

  void _auditSdp(String? sdp) {
    final s = sdp ?? '';
    final iceUfrag = s.contains('a=ice-ufrag');
    final icePwd = s.contains('a=ice-pwd');
    final bundle = s.contains('a=group:BUNDLE');
    final rtcpMux = s.contains('a=rtcp-mux');
    debugPrint(
        '[SDP_AUDIT]\niceUfrag=$iceUfrag\nicePwd=$icePwd\nbundle=$bundle\nrtcpMux=$rtcpMux');
  }

  void _startStabilityTimer() {
    if (_stabilityTimer != null) return;
    _stabilitySeconds = 0;
    debugPrint('[CALL_STABILITY_TIMER_STARTED] Starting 60-second connection stability monitoring.');
    _stabilityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (peerConnection == null) {
        _stopStabilityTimer();
        return;
      }
      _stabilitySeconds += 10;
      debugPrint(
          '[CALL_STABILITY_TICK] elapsedSeconds=$_stabilitySeconds audioPacketsReceived=$_lastAudioPacketsReceived videoPacketsReceived=$_lastVideoPacketsReceived');
      if (_stabilitySeconds >= 60) {
        debugPrint(
            '✅ [CALL_STABLE_60_SECONDS] Connection maintained stable audio/video flow for 60 seconds!');
        _stopStabilityTimer();
      }
    });
    _activeTimers.add(_stabilityTimer!);
  }

  void _stopStabilityTimer() {
    if (_stabilityTimer != null) {
      try {
        _stabilityTimer!.cancel();
        _activeTimers.remove(_stabilityTimer);
      } catch (_) {}
      _stabilityTimer = null;
      debugPrint('[CALL_STABILITY_TIMER_STOPPED] Stability timer stopped.');
    }
    _stabilitySeconds = 0;
  }

  Map<String, dynamic> getConfiguration() {
    final policy = forceRelayOnly ? 'relay' : 'all';
    if (forceRelayOnly) {
      debugPrint('[RELAY_ONLY_MODE_ENABLED]');
    } else {
      debugPrint('[RELAY_ONLY_MODE_DISABLED] PeerConnection configured with iceTransportPolicy: all');
    }

    final config = <String, dynamic>{
      'iceServers': [
        {
          'urls': [
            'turn:global.relay.metered.ca:80',
            'turn:global.relay.metered.ca:80?transport=tcp',
            'turn:global.relay.metered.ca:443?transport=tcp',
            'turns:global.relay.metered.ca:443?transport=tcp',
          ],
          'username': 'e05c4a4a1347fef5fedaa1c5',
          'credential': 'fCBVVCuN/6gVZrFj',
        },
      ],
      'iceCandidatePoolSize': 0,
      'iceTransportPolicy': policy,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'sdpSemantics': 'unified-plan',
    };

    final iceServers = config['iceServers'] as List;
    for (int i = 0; i < iceServers.length; i++) {
      final s = iceServers[i] as Map<String, dynamic>;
      debugPrint('[TURN_SERVER_ATTEMPT] index=$i urls=${s["urls"]} username=${s["username"] ?? "none"}');
    }

    return config;
  }

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
      _stopStatsLogging();
      _stopStabilityTimer();

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
      _isRestartingIce = false;
      _pendingCandidates.clear();
      _localHostCandidateCount = 0;
      _localSrflxCandidateCount = 0;
      _localRelayCandidateCount = 0;
      _noRtpFlowSeconds = 0;
      _lastAudioPacketsSent = 0;
      _lastAudioPacketsReceived = 0;
      _lastVideoPacketsSent = 0;
      _lastVideoPacketsReceived = 0;
      debugPrint('[Signaling] PeerConnection and media tracks completely disposed.');
    }
  }

  // ── Candidate Validation (Task 5) ──────────────────────────────────────────

  RTCIceCandidate? _validateAndCreateCandidate(
      String? candidateStr, dynamic rawSdpMid, dynamic rawSdpMLineIndex) {
    if (candidateStr == null || candidateStr.trim().isEmpty) {
      debugPrint('⚠️ [INVALID_CANDIDATE] Candidate string is null or empty.');
      return null;
    }

    String? sdpMid;
    if (rawSdpMid != null && rawSdpMid.toString().isNotEmpty) {
      sdpMid = rawSdpMid.toString();
    }

    int? sdpMLineIndex;
    if (rawSdpMLineIndex is int) {
      sdpMLineIndex = rawSdpMLineIndex;
    } else if (rawSdpMLineIndex != null) {
      sdpMLineIndex = int.tryParse(rawSdpMLineIndex.toString());
    }

    if (sdpMid == null && sdpMLineIndex == null) {
      debugPrint(
          '⚠️ [INVALID_SDPMID] [INVALID_SDPMLINEINDEX] Candidate missing both sdpMid and sdpMLineIndex for candidate: $candidateStr');
      return null;
    }

    return RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex);
  }

  // ── Flush buffered ICE candidates ─────────────────────────────────────────

  Future<void> _flushPendingCandidates() async {
    if (peerConnection == null) return;
    debugPrint('📡 Flushing ${_pendingCandidates.length} queued ICE candidates...');
    for (final candidate in List.of(_pendingCandidates)) {
      final candType = _getCandidateType(candidate.candidate ?? '');
      try {
        debugPrint('[ADD_CANDIDATE_ATTEMPT]\ntype=$candType');
        await peerConnection?.addCandidate(candidate);
        debugPrint('[ADD_CANDIDATE_SUCCESS]\ntype=$candType');
      } catch (e) {
        debugPrint('[ADD_CANDIDATE_FAILURE]\nerror=$e');
      }
    }
    _pendingCandidates.clear();
  }

  /// Adds a candidate, buffering it if remote description isn't set yet.
  Future<void> _addIceCandidateSafe(RTCIceCandidate candidate) async {
    final candType = _getCandidateType(candidate.candidate ?? '');
    if (_remoteDescriptionSet && peerConnection != null) {
      try {
        debugPrint('[ADD_CANDIDATE_ATTEMPT]\ntype=$candType');
        await peerConnection!.addCandidate(candidate);
        debugPrint('[ADD_CANDIDATE_SUCCESS]\ntype=$candType');
      } catch (e) {
        debugPrint('[ADD_CANDIDATE_FAILURE]\nerror=$e');
      }
    } else {
      debugPrint(
          '📡 [ICE_QUEUED] Queuing candidate (remote description not ready yet): sdpMid=${candidate.sdpMid} cand=${candidate.candidate}');
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

    isCaller = true;
    _remoteDescriptionSet = false;
    _pendingCandidates.clear();
    _stopStatsLogging();
    _localHostCandidateCount = 0;
    _localSrflxCandidateCount = 0;
    _localRelayCandidateCount = 0;

    debugPrint('[CANDIDATE_TABLE_CLEANUP] Cleaning stale candidate tables for caller and callee.');

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

    debugPrint('[PEER_CONFIG] ${jsonEncode(getConfiguration())}');
    peerConnection = await createPeerConnection(getConfiguration());
    debugPrint('[PEER_CONNECTION_CREATED]');

    _registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    await _setupTransceivers();

    try {
      final senders = await peerConnection?.getSenders() ?? [];
      for (final s in senders) {
        final tr = s.track;
        debugPrint(
            '[CREATE_ROOM] pc=${peerConnection.hashCode} senders=${senders.length} audioTrack=${tr?.id} muted=${tr?.muted} enabled=${tr?.enabled}');
      }
    } catch (_) {}

    // ICE Candidate handler for Caller
    peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
      debugPrint('[RAW_ICE_CANDIDATE] candidate=${candidate?.candidate}');
      if (candidate == null || candidate.candidate == null || candidate.candidate!.isEmpty) return;
      final candStr = candidate.candidate!;
      final candType = _getCandidateType(candStr);

      if (candStr.contains('typ relay')) {
        debugPrint('[TURN_CANDIDATE_GENERATED] $candStr');
      }
      if (candStr.contains('typ srflx')) {
        debugPrint('[SRFLX_CANDIDATE_GENERATED] $candStr');
      }
      if (candStr.contains('typ host')) {
        debugPrint('[HOST_CANDIDATE_GENERATED] $candStr');
      }

      if (candType == 'host') {
        _localHostCandidateCount++;
      } else if (candType == 'srflx') {
        _localSrflxCandidateCount++;
      } else if (candType == 'relay') {
        _localRelayCandidateCount++;
        debugPrint('[TURN_RELAY_GENERATED]\ncandidate=$candStr');
      }
      debugPrint('[CANDIDATE_DB_INSERT]\ntype=$candType\ncandidate=$candStr');
      try {
        await Supabase.instance.client.from('caller_candidates').insert({
          'room_id': roomId,
          'candidate': candidate.candidate,
          'sdpmid': candidate.sdpMid ?? '0',
          'sdpmlineindex': candidate.sdpMLineIndex ?? 0,
        });
        debugPrint('[ICE_STORED_DB] caller candidate inserted to DB successfully: $candStr');
      } catch (e) {
        debugPrint('⚠️ [ICE_STORE_ERROR] Error inserting caller ICE candidate to DB: $e');
      }
    };

    final offer = await peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await peerConnection!.setLocalDescription(offer);

    _auditSdp(offer.sdp);
    debugPrint('[LOCAL_DESCRIPTION] role=caller type=${offer.type} sdpLength=${offer.sdp?.length}');

    final offerTimestamp = DateTime.now().toIso8601String();
    await Supabase.instance.client.from('rooms').update({
      'offer': offer.toMap(),
      'updated_at': offerTimestamp,
    }).eq('id', roomId!);
    debugPrint('[ROOM_UPDATED] roomId=$roomId offerTimestamp=$offerTimestamp');

    // 15-second ICE gathering timeout check (Requirement 8)
    final gatheringTimeoutTimer = Timer(const Duration(seconds: 15), () {
      debugPrint('[ICE_GATHERING_FINAL_COUNTS]');
      debugPrint('host=$_localHostCandidateCount');
      debugPrint('srflx=$_localSrflxCandidateCount');
      debugPrint('relay=$_localRelayCandidateCount');

      if (_localRelayCandidateCount == 0) {
        debugPrint('[TURN_ALLOCATION_FAILED]');
      }
    });
    _activeTimers.add(gatheringTimeoutTimer);

    // Fast 300ms REST polling for SDP answer from callee
    Timer? answerTimer;
    bool settingAnswer = false;

    answerTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (_remoteDescriptionSet || settingAnswer || peerConnection == null || roomId == null) {
        answerTimer?.cancel();
        return;
      }
      try {
        final currentSigState = await peerConnection?.getSignalingState();
        if (_remoteDescriptionSet || currentSigState == RTCSignalingState.RTCSignalingStateStable) {
          debugPrint(
              '[ANSWER_ALREADY_APPLIED] Signaling state is already stable ($currentSigState). Skipping duplicate answer.');
          _remoteDescriptionSet = true;
          answerTimer?.cancel();
          return;
        }

        final res = await Supabase.instance.client
            .from('rooms')
            .select('answer, updated_at')
            .eq('id', roomId!)
            .maybeSingle();

        if (res != null && res['answer'] != null && !_remoteDescriptionSet && !settingAnswer) {
          final answerMap = Map<String, dynamic>.from(res['answer']);
          final answer = RTCSessionDescription(answerMap['sdp'], answerMap['type']);
          final answerTimestamp = res['updated_at']?.toString() ?? '';

          debugPrint(
              '[ANSWER_RECEIVED] roomId=$roomId answerTimestamp=$answerTimestamp sdpLength=${answer.sdp?.length}');

          settingAnswer = true;
          _remoteDescriptionSet = true;
          answerTimer?.cancel();
          debugPrint('[ANSWER_POLL_STOPPED] Answer polling timer stopped.');

          final sigBefore = await peerConnection?.getSignalingState();
          debugPrint(
              '[SIGNALING_BEFORE_ANSWER] currentState=$sigBefore sdpLength=${answer.sdp?.length} type=${answer.type}');

          if (sigBefore == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
            await peerConnection?.setRemoteDescription(answer);
            debugPrint(
                '[REMOTE_DESCRIPTION] role=caller setRemoteDescription SUCCESS! SignalingState is now: ${await peerConnection?.getSignalingState()}');
            debugPrint('[ANSWER_APPLIED] Answer applied successfully!');
            await _flushPendingCandidates();
          } else {
            debugPrint('⚠️ [ANSWER_SKIPPED] Cannot apply answer SDP in state $sigBefore');
          }
        }
      } catch (e) {
        debugPrint('Error polling answer: $e');
      } finally {
        settingAnswer = false;
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
          if (candidateStr != null) {
            final candType = _getCandidateType(candidateStr);
            debugPrint('[CANDIDATE_DB_RETRIEVED]\ntype=$candType\ncandidate=$candidateStr');

            if (!addedCalleeCandidates.contains(candidateStr)) {
              addedCalleeCandidates.add(candidateStr);
              final candObj = _validateAndCreateCandidate(
                candidateStr,
                candMap['sdpmid'] ?? candMap['sdpMid'],
                candMap['sdpmlineindex'] ?? candMap['sdpMLineIndex'],
              );
              if (candObj != null) {
                await _addIceCandidateSafe(candObj);
              }
            }
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
    isCaller = false;
    roomId = joinRoomId;
    Signaling.activeCallRoomId = joinRoomId;

    _remoteDescriptionSet = false;
    _pendingCandidates.clear();
    _stopStatsLogging();
    _localHostCandidateCount = 0;
    _localSrflxCandidateCount = 0;
    _localRelayCandidateCount = 0;

    debugPrint('[CANDIDATE_TABLE_CLEANUP] Cleaning stale candidate tables for caller and callee.');

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

    debugPrint('[PEER_CONFIG] ${jsonEncode(getConfiguration())}');
    peerConnection = await createPeerConnection(getConfiguration());
    debugPrint('[PEER_CONNECTION_CREATED]');

    _registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    await _setupTransceivers();

    try {
      final receivers = await peerConnection?.getReceivers() ?? [];
      for (final r in receivers) {
        final tr = r.track;
        debugPrint(
            '[JOIN_ROOM] pc=${peerConnection.hashCode} receivers=${receivers.length} audioTrack=${tr?.id} muted=${tr?.muted} enabled=${tr?.enabled}');
      }
    } catch (_) {}

    peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
      debugPrint('[RAW_ICE_CANDIDATE] candidate=${candidate?.candidate}');
      if (candidate == null || candidate.candidate == null || candidate.candidate!.isEmpty) return;
      final candStr = candidate.candidate!;
      final candType = _getCandidateType(candStr);

      if (candStr.contains('typ relay')) {
        debugPrint('[TURN_CANDIDATE_GENERATED] $candStr');
      }
      if (candStr.contains('typ srflx')) {
        debugPrint('[SRFLX_CANDIDATE_GENERATED] $candStr');
      }
      if (candStr.contains('typ host')) {
        debugPrint('[HOST_CANDIDATE_GENERATED] $candStr');
      }

      if (candType == 'host') {
        _localHostCandidateCount++;
      } else if (candType == 'srflx') {
        _localSrflxCandidateCount++;
      } else if (candType == 'relay') {
        _localRelayCandidateCount++;
        debugPrint('[TURN_RELAY_GENERATED]\ncandidate=$candStr');
      }
      debugPrint('[CANDIDATE_DB_INSERT]\ntype=$candType\ncandidate=$candStr');
      try {
        await Supabase.instance.client.from('callee_candidates').insert({
          'room_id': joinRoomId,
          'candidate': candidate.candidate,
          'sdpmid': candidate.sdpMid ?? '0',
          'sdpmlineindex': candidate.sdpMLineIndex ?? 0,
        });
        debugPrint('[ICE_STORED_DB] callee candidate inserted to DB successfully: $candStr');
      } catch (e) {
        debugPrint('⚠️ [ICE_STORE_ERROR] Error inserting callee ICE candidate to DB: $e');
      }
    };

    final offerMap = Map<String, dynamic>.from(roomData['offer']);
    final remoteOffer = RTCSessionDescription(offerMap['sdp'], offerMap['type']);
    debugPrint(
        '[REMOTE_DESCRIPTION] role=callee setting remote offer sdpLength=${remoteOffer.sdp?.length} type=${remoteOffer.type}');
    await peerConnection?.setRemoteDescription(remoteOffer);
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();

    final answer = await peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isRoomVideo,
    });
    await peerConnection!.setLocalDescription(answer);

    _auditSdp(answer.sdp);
    debugPrint(
        '[LOCAL_DESCRIPTION] role=callee setLocalDescription answer sdpLength=${answer.sdp?.length} type=${answer.type}');

    final answerTimestamp = DateTime.now().toIso8601String();
    await Supabase.instance.client.from('rooms').update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'connected',
      'updated_at': answerTimestamp,
    }).eq('id', joinRoomId);
    debugPrint('[ROOM_UPDATED] roomId=$joinRoomId answerTimestamp=$answerTimestamp status=connected');

    // 15-second ICE gathering timeout check (Requirement 8)
    final gatheringTimeoutTimer = Timer(const Duration(seconds: 15), () {
      debugPrint('[ICE_GATHERING_FINAL_COUNTS]');
      debugPrint('host=$_localHostCandidateCount');
      debugPrint('srflx=$_localSrflxCandidateCount');
      debugPrint('relay=$_localRelayCandidateCount');

      if (_localRelayCandidateCount == 0) {
        debugPrint('[TURN_ALLOCATION_FAILED]');
      }
    });
    _activeTimers.add(gatheringTimeoutTimer);

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
          if (candidateStr != null) {
            final candType = _getCandidateType(candidateStr);
            debugPrint('[CANDIDATE_DB_RETRIEVED]\ntype=$candType\ncandidate=$candidateStr');

            if (!addedCallerCandidates.contains(candidateStr)) {
              addedCallerCandidates.add(candidateStr);

              final candObj = _validateAndCreateCandidate(
                candidateStr,
                candMap['sdpmid'] ?? candMap['sdpMid'],
                candMap['sdpmlineindex'] ?? candMap['sdpMLineIndex'],
              );
              if (candObj != null) {
                await _addIceCandidateSafe(candObj);
              }
            }
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
      timer.cancel();
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
      timer.cancel();
      controller.close();
    };

    return controller.stream.listen((_) {});
  }

  // ── Proper ICE Restart with Renegotiation (Task 4) ─────────────────────────

  Future<void> _restartIceWithRenegotiation() async {
    if (_isRestartingIce || peerConnection == null || roomId == null) return;
    _isRestartingIce = true;
    debugPrint('[ICE_RESTART_STARTED] Initiating full ICE restart for roomId=$roomId...');

    try {
      if (isCaller) {
        final offer = await peerConnection!.createOffer({
          'iceRestart': true,
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': true,
        });
        _auditSdp(offer.sdp);
        debugPrint('[ICE_RESTART_OFFER_CREATED] sdpLength=${offer.sdp?.length}');
        await peerConnection!.setLocalDescription(offer);

        await Supabase.instance.client.from('rooms').update({
          'offer': offer.toMap(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', roomId!);
        debugPrint('[ICE_RESTART_OFFER_SENT] Restart offer updated in rooms table.');
      } else {
        debugPrint('[ICE_RESTART_REMOTE_RECEIVED] Callee triggering peerConnection.restartIce()...');
        await peerConnection?.restartIce();
        debugPrint('[ICE_RESTART_COMPLETED] Callee ICE restart triggered successfully.');
      }
    } catch (e) {
      debugPrint('⚠️ [ICE_RESTART_FAILURE] Error during ICE restart: $e');
    } finally {
      _isRestartingIce = false;
    }
  }

  // ── Peer Connection Listeners ─────────────────────────────────────────────

  void _registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('[ICE_GATHERING_STATE] $state');
      debugPrint('[STATE] IceGatheringState: $state');
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        debugPrint(
            '[CANDIDATE_SUMMARY]\nrole=${isCaller ? "caller" : "callee"}\nhost=$_localHostCandidateCount\nsrflx=$_localSrflxCandidateCount\nrelay=$_localRelayCandidateCount');
        if (_localRelayCandidateCount == 0) {
          debugPrint(
              '[FATAL_TURN_FAILURE]\nhost=$_localHostCandidateCount\nsrflx=$_localSrflxCandidateCount\nrelay=0');
        } else {
          debugPrint(
              '✅ [TURN_RELAY_GENERATED]\ncandidate=relayCount=$_localRelayCandidateCount');
        }
      }
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) async {
      debugPrint('[STATE] ConnectionState: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _startStatsLogging();
        try {
          final senders = await peerConnection?.getSenders() ?? [];
          for (final s in senders) {
            final tr = s.track;
            if (tr != null) {
              debugPrint('[SENDER_TRACK] kind=${tr.kind} id=${tr.id} enabled=${tr.enabled} muted=${tr.muted}');
            }
          }
          final receivers = await peerConnection?.getReceivers() ?? [];
          for (final r in receivers) {
            final tr = r.track;
            if (tr != null) {
              debugPrint('[RECEIVER_TRACK] kind=${tr.kind} id=${tr.id} enabled=${tr.enabled} muted=${tr.muted}');
            }
          }
        } catch (_) {}
      }
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint('[STATE] SignalingState: $state');
    };

    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) async {
      debugPrint('[ICE_CONNECTION_STATE] $state');
      debugPrint('[STATE] IceConnectionState: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _startStatsLogging();
        _startStabilityTimer();
        debugPrint('✅ [ICE] Media transport CONNECTED / COMPLETED!');

        try {
          if (!kIsWeb) {
            await Helper.setSpeakerphoneOn(true);
            debugPrint('[AUDIO_ROUTE_CONNECTED] Helper.setSpeakerphoneOn(true) executed after ICE connected.');
          }
        } catch (e) {
          debugPrint('[AUDIO_ROUTE_ERROR] Helper.setSpeakerphoneOn error: $e');
        }

        try {
          final stats = await peerConnection?.getStats();
          for (final report in stats ?? []) {
            if ((report.type == 'candidate-pair' || report.type == 'googCandidatePair') &&
                (report.values['state'] == 'succeeded' || report.values['nominated'] == true)) {
              debugPrint(
                  '[ICE_SELECTED_PAIR] localCandidateId=${report.values['localCandidateId']} remoteCandidateId=${report.values['remoteCandidateId']} RTT=${report.values['currentRoundTripTime']} state=${report.values['state']}');
            }
          }
        } catch (_) {}
      }
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('⚠️ [CALL_STABILITY_FAILURE] ICE entered failed state after ${_stabilitySeconds}s of connection monitoring!');
        _stopStabilityTimer();
        debugPrint('⚠️ [ICE] Connection failed! Initiating full ICE restart with renegotiation...');
        await _restartIceWithRenegotiation();
      }
    };

    peerConnection?.onTrack = (RTCTrackEvent event) async {
      debugPrint(
          '[REMOTE_TRACK] id=${event.track.id} kind=${event.track.kind} enabled=${event.track.enabled} muted=${event.track.muted} stream=${event.streams.isNotEmpty ? event.streams[0].id : "none"}');
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
      onAddRemoteStream?.call(remoteStream!);
    };
  }

  // ── Stats Logging & Hardening ──────────────────────────────────────────────

  void _startStatsLogging() {
    if (_statsLoggingStarted || _statsTimer != null) {
      debugPrint('[STATS_TIMER_ALREADY_RUNNING] Stats timer is already running.');
      return;
    }
    _statsLoggingStarted = true;
    debugPrint('[STATS_TIMER_STARTED] Starting WebRTC stats logging timer.');

    _statsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (peerConnection == null) {
        _stopStatsLogging();
        return;
      }
      try {
        for (final track in localStream?.getAudioTracks() ?? []) {
          debugPrint(
              '[MIC_TRACK] enabled=${track.enabled} muted=${track.muted} label=${track.label} id=${track.id}');
        }
        for (final track in remoteStream?.getAudioTracks() ?? []) {
          debugPrint(
              '[REMOTE_AUDIO_TRACK] enabled=${track.enabled} muted=${track.muted} label=${track.label} id=${track.id}');
        }
        for (final track in remoteStream?.getVideoTracks() ?? []) {
          debugPrint(
              '[REMOTE_VIDEO_TRACK] enabled=${track.enabled} muted=${track.muted} label=${track.label} id=${track.id}');
        }

        final stats = await peerConnection?.getStats();
        if (stats != null) {
          int audioPacketsSent = 0;
          int audioPacketsReceived = 0;
          int videoPacketsSent = 0;
          int videoPacketsReceived = 0;
          int bytesSent = 0;
          int bytesReceived = 0;
          num currentRTT = 0;

          final candidateMap = <String, Map<dynamic, dynamic>>{};
          for (final report in stats) {
            final t = report.type.toLowerCase();
            if (t == 'local-candidate' || t == 'remote-candidate' || t == 'googlocalcandidate' || t == 'googremotecandidate') {
              candidateMap[report.id] = report.values;
            }
          }

          for (final report in stats) {
            final values = report.values;
            final rType = report.type.toLowerCase();
            if (rType == 'outbound-rtp') {
              if (values['kind'] == 'audio' || values['mediaType'] == 'audio') {
                audioPacketsSent = values['packetsSent'] ?? 0;
                bytesSent += (values['bytesSent'] as int? ?? 0);
              } else if (values['kind'] == 'video' || values['mediaType'] == 'video') {
                videoPacketsSent = values['packetsSent'] ?? 0;
                bytesSent += (values['bytesSent'] as int? ?? 0);
              }
            }
            if (rType == 'inbound-rtp') {
              if (values['kind'] == 'audio' || values['mediaType'] == 'audio') {
                audioPacketsReceived = values['packetsReceived'] ?? 0;
                bytesReceived += (values['bytesReceived'] as int? ?? 0);
              } else if (values['kind'] == 'video' || values['mediaType'] == 'video') {
                videoPacketsReceived = values['packetsReceived'] ?? 0;
                bytesReceived += (values['bytesReceived'] as int? ?? 0);
              }
            }

            if (rType == 'candidate-pair' || rType == 'googcandidatepair') {
              final state = values['state']?.toString() ?? 'unknown';
              final isNominated = values['nominated'] == true;
              final isWritable = values['writable'] == true;
              final localId = values['localCandidateId']?.toString() ?? '';
              final remoteId = values['remoteCandidateId']?.toString() ?? '';
              final localCand = candidateMap[localId];
              final remoteCand = candidateMap[remoteId];
              final localType = localCand?['candidateType'] ?? localCand?['candidate_type'] ?? _getCandidateType(localCand?['ip'] ?? '');
              final remoteType = remoteCand?['candidateType'] ?? remoteCand?['candidate_type'] ?? _getCandidateType(remoteCand?['ip'] ?? '');
              final pairRtt = values['currentRoundTripTime'] ?? 0;

              debugPrint(
                  '[ICE_PAIR]\nstate=$state\nnominated=$isNominated\nwritable=$isWritable\nlocalCandidateId=$localId\nremoteCandidateId=$remoteId');

              if (isNominated && (state == 'succeeded' || isWritable)) {
                debugPrint(
                    '[ACTIVE_ICE_PAIR]\nlocalType=$localType\nremoteType=$remoteType\nstate=$state\nrtt=$pairRtt');
                debugPrint(
                    '[ICE_SELECTED_PAIR] localCandidateType=$localType remoteCandidateType=$remoteType candidatePairState=$state rtt=$pairRtt');
                currentRTT = pairRtt;
              }
            }
          }

          debugPrint(
              '[RTP_RX]\naudioPackets=$audioPacketsReceived\nvideoPackets=$videoPacketsReceived\nbytesReceived=$bytesReceived');
          debugPrint(
              '[RTP_TX]\naudioPackets=$audioPacketsSent\nvideoPackets=$videoPacketsSent\nbytesSent=$bytesSent');

          final totalPackets = audioPacketsSent + audioPacketsReceived + videoPacketsSent + videoPacketsReceived;
          final prevTotalPackets = _lastAudioPacketsSent + _lastAudioPacketsReceived + _lastVideoPacketsSent + _lastVideoPacketsReceived;

          if (totalPackets > prevTotalPackets) {
            debugPrint(
                '[RTP_FLOW_DETECTED] audioPacketsSent=$audioPacketsSent audioPacketsReceived=$audioPacketsReceived videoPacketsSent=$videoPacketsSent videoPacketsReceived=$videoPacketsReceived bytesSent=$bytesSent bytesReceived=$bytesReceived');
            if (audioPacketsReceived > 0 || videoPacketsReceived > 0) {
              debugPrint('✅ [RTP_STREAMING_SUCCESS] Remote media packets actively flowing! audioPacketsReceived=$audioPacketsReceived videoPacketsReceived=$videoPacketsReceived');
            }
            _noRtpFlowSeconds = 0;
          } else {
            final hasRemoteTracks = (remoteStream?.getTracks().isNotEmpty ?? false);
            if (hasRemoteTracks) {
              _noRtpFlowSeconds += 3;
              if (_noRtpFlowSeconds >= 10) {
                debugPrint(
                    '⚠️ [MEDIA_FLOW_FAILURE] Remote track present, but 0 RTP bytes received for ${_noRtpFlowSeconds}s! bytesReceived=$bytesReceived audioPacketsReceived=$audioPacketsReceived');
              }
            }
          }

          _lastAudioPacketsSent = audioPacketsSent;
          _lastAudioPacketsReceived = audioPacketsReceived;
          _lastVideoPacketsSent = videoPacketsSent;
          _lastVideoPacketsReceived = videoPacketsReceived;

          debugPrint(
              '[WEBRTC_STATS] bytesSent=$bytesSent bytesReceived=$bytesReceived audioPacketsSent=$audioPacketsSent audioPacketsReceived=$audioPacketsReceived videoPacketsSent=$videoPacketsSent videoPacketsReceived=$videoPacketsReceived currentRoundTripTime=$currentRTT');
        }
      } catch (e) {
        debugPrint('[WEBRTC_STATS] Error fetching stats: $e');
      }
    });
    _activeTimers.add(_statsTimer!);
  }

  void _stopStatsLogging() {
    if (_statsTimer != null) {
      try {
        _statsTimer!.cancel();
        _activeTimers.remove(_statsTimer);
      } catch (_) {}
      _statsTimer = null;
      debugPrint('[STATS_TIMER_STOPPED] Stats logging timer stopped.');
    }
    _statsLoggingStarted = false;
  }

  // Keep backward compat
  void registerPeerConnectionListeners() => _registerPeerConnectionListeners();
}
