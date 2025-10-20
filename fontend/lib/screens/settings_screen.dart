import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<AlarmModel> _alarms = [];
  Timer? _alarmChecker;

  // Speech
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _voiceText = '';
  String _voiceTextFinal = '';
  double _soundLevel = 0.0; // 0..(~100) tuỳ nền tảng
  bool _hasFinalResult = false;
  AlarmModel? _pendingParsedAlarm; // báo thức parse sẵn, bấm Lưu để thêm

  BuildContext? _listeningDialogContext;
  void Function(void Function())? _overlaySetState; // setState cho overlay

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudio();
    _startAlarmChecker();
  }

  // Dừng checker khi app background để tiết kiệm tài nguyên
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAlarmChecker();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _alarmChecker?.cancel();
      _alarmChecker = null;
    }
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setAsset('assets/alarm_sound.mp3'); // asset có sẵn
    } catch (e) {
      // Fallback: URL khi thiếu asset
      try {
        await _audioPlayer.setUrl(
          'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        );
      } catch (_) {
        debugPrint('Error initializing audio: $e');
      }
    }
  }

  void _startAlarmChecker() {
    _alarmChecker?.cancel();
    _alarmChecker = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _checkAlarms(),
    );
  }

  void _checkAlarms() {
    final now = DateTime.now();
    for (final alarm in _alarms) {
      if (!alarm.isActive) continue;
      final currentKey = alarm.triggerKeyFor(now);
      if (alarm.lastTriggeredKey == currentKey) continue;

      final isSameHourMinute =
          now.hour == alarm.time.hour && now.minute == alarm.time.minute;
      final nearSecondZero =
          now.second == 0 || (now.second == 1 && now.millisecond < 300);

      if (isSameHourMinute && nearSecondZero) {
        _triggerAlarm(alarm, currentKey);
      }
    }
  }

  Future<void> _triggerAlarm(AlarmModel alarm, String triggerKey) async {
    alarm.lastTriggeredKey = triggerKey;
    await _playAlarmSound();
    if (!mounted) return;
    _showAlarmDialog(alarm);

    if (!alarm.repeatDaily) {
      alarm.isActive = false; // báo thức 1 lần
    }
    setState(() {});
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  Future<void> _stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  void _showAlarmDialog(AlarmModel alarm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.alarm, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Báo thức!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              alarm.time.format(context),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(alarm.label.isEmpty ? 'Báo thức' : alarm.label),
            const SizedBox(height: 12),
            if (alarm.repeatDaily)
              const Text(
                '(Lặp lại hằng ngày)',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _stopAlarmSound();
              Navigator.pop(context);
            },
            child: const Text('Tắt'),
          ),
          ElevatedButton(
            onPressed: () {
              _stopAlarmSound();
              Navigator.pop(context);
              _snoozeAlarm(alarm);
            },
            child: const Text('Báo lại (5 phút)'),
          ),
        ],
      ),
    );
  }

  void _snoozeAlarm(AlarmModel alarm) {
    final now = DateTime.now();
    final snooze = now.add(const Duration(minutes: 5));
    _alarms.add(
      AlarmModel(
        time: TimeOfDay(hour: snooze.hour, minute: snooze.minute),
        label: '${alarm.label.isEmpty ? 'Báo thức' : alarm.label} (Snooze)',
        isActive: true,
        repeatDaily: false,
      ),
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo thức sẽ kêu lại sau 5 phút')),
    );
  }

  Future<void> _addAlarm() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;

    final info = await _showCreateDialog();
    if (info == null) return;

    _alarms.add(
      AlarmModel(
        time: picked,
        label: info.label,
        isActive: true,
        repeatDaily: info.repeatDaily,
      ),
    );
    setState(() {});
  }

  Future<_CreateAlarmInfo?> _showCreateDialog() async {
    final labelCtrl = TextEditingController();
    bool repeatDaily = true;

    final result = await showDialog<_CreateAlarmInfo>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Thông tin báo thức'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  hintText: 'Nhãn (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: repeatDaily,
                    onChanged: (v) {
                      repeatDaily = v ?? true;
                      setLocal(() {});
                    },
                  ),
                  const Text('Lặp hằng ngày'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                _CreateAlarmInfo(labelCtrl.text, repeatDaily),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    labelCtrl.dispose();
    return result;
  }

  void _deleteAlarm(int index) {
    _alarms.removeAt(index);
    setState(() {});
  }

  void _toggleAlarm(int index) {
    _alarms[index].isActive = !_alarms[index].isActive;
    setState(() {});
  }

  // ================== LISTENING UI (overlay) ==================

  void _showListeningOverlay() {
    if (_listeningDialogContext != null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _listeningDialogContext = ctx;
        return WillPopScope(
          onWillPop: () async {
            _stopListening();
            return true;
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12),
                ],
              ),
              child: StatefulBuilder(
                builder: (ctx, setLocal) {
                  // lưu setState cục bộ để update overlay từ callback bên ngoài
                  _overlaySetState = setLocal;

                  // Chuẩn hoá 0..1 và ép double
                  final double levelNorm = (_soundLevel <= 1.0)
                      ? _soundLevel.clamp(0.0, 1.0).toDouble()
                      : (_soundLevel / 100.0).clamp(0.0, 1.0).toDouble();

                  final bool isReceiving = levelNorm > 0.05;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isListening ? 'Đang nghe...' : 'Đã dừng',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              value: _isListening
                                  ? levelNorm
                                  : null, // null => indeterminate
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isReceiving ? 'Đang nhận âm' : 'Không nhận',
                            style: TextStyle(
                              color: isReceiving ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _voiceText.isEmpty
                            ? 'Hãy nói: "7 giờ", "8 giờ 30", "9 tối"...'
                            : _voiceText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⏱️ Thời gian nghe: 10 giây',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (_hasFinalResult) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Kết quả: "${_voiceTextFinal}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _pendingParsedAlarm != null
                              ? '⏰ Sẽ đặt: ${_pendingParsedAlarm!.time.format(context)}'
                              : '❌ Không nhận diện được thời gian',
                          style: TextStyle(
                            color: _pendingParsedAlarm != null
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _stopListening(); // dừng và đóng overlay
                              },
                              icon: const Icon(Icons.stop),
                              label: const Text('Dừng'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _hasFinalResult && _pendingParsedAlarm != null
                                  ? () {
                                      _savePendingAlarm();
                                    }
                                  : null,
                              icon: const Icon(Icons.save),
                              label: const Text('Lưu'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideListeningOverlay() {
    if (_listeningDialogContext != null && mounted) {
      Navigator.of(_listeningDialogContext!).pop();
      _listeningDialogContext = null;
      _overlaySetState = null;
    }
  }

  // ================== SPEECH FLOW ==================

  Future<void> _startListening() async {
    try {
      // Kiểm tra và yêu cầu quyền mic
      debugPrint('Checking microphone permission...');
      var status = await Permission.microphone.status;
      debugPrint('Current permission status: $status');

      // Nếu chưa có quyền, hiển thị dialog giải thích trước
      if (status.isDenied) {
        final shouldRequest = await _showPermissionRequestDialog();
        if (shouldRequest != true) {
          debugPrint('User cancelled permission request');
          return;
        }

        debugPrint('Requesting microphone permission...');
        status = await Permission.microphone.request();
        debugPrint('Permission after request: $status');
      }

      // Nếu bị từ chối vĩnh viễn, hướng dẫn vào Settings
      if (status.isPermanentlyDenied) {
        final shouldOpenSettings = await _showPermissionDeniedDialog();
        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
        return;
      }

      // Nếu vẫn không có quyền sau khi request
      if (!status.isGranted) {
        _showErrorDialog(
          'Không có quyền ghi âm',
          'Cần cấp quyền ghi âm để sử dụng tính năng giọng nói.',
        );
        return;
      }

      debugPrint('Permission granted, initializing speech...');

      // Khởi tạo Speech-to-Text
      _speechAvailable = await _speech.initialize(
        onStatus: (s) {
          debugPrint('Speech status: $s');
          // 'listening' / 'notListening' / 'done' (tuỳ nền tảng)
          if (s.contains('listening')) {
            _isListening = true;
          } else if (s.contains('notListening') || s.contains('done')) {
            _isListening = false;
          }
          if (mounted) {
            setState(() {}); // cập nhật icon app bar
          }
          _overlaySetState?.call(() {}); // cập nhật overlay nếu đang mở
        },
        onError: (e) {
          debugPrint('Speech error: $e');

          // Xử lý timeout thân thiện hơn
          if (e.errorMsg.contains('error_speech_timeout') ||
              e.errorMsg.contains('timeout')) {
            _stopListening();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '⏱️ Hết thời gian nghe. Vui lòng thử lại và nói rõ hơn.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }

          // Các lỗi khác
          _stopListening();
          _showErrorDialog(
            'Lỗi ghi âm',
            'Có lỗi xảy ra: ${e.errorMsg}\n\nVui lòng thử lại hoặc khởi động lại ứng dụng.',
          );
        },
      );

      debugPrint('Speech initialize result: $_speechAvailable');

      if (!_speechAvailable) {
        _showErrorDialog(
          'Không thể khởi tạo ghi âm',
          'Thiết bị có thể không hỗ trợ tính năng Speech-to-Text hoặc có vấn đề với microphone.',
        );
        return;
      }
    } catch (e) {
      debugPrint('Error in _startListening: $e');
      _showErrorDialog(
        'Lỗi không xác định',
        'Có lỗi xảy ra: $e\n\nVui lòng thử lại.',
      );
      return;
    }

    // Reset state
    _isListening = true;
    _voiceText = '';
    _voiceTextFinal = '';
    _hasFinalResult = false;
    _pendingParsedAlarm = null;
    _soundLevel = 0;
    if (mounted) {
      setState(() {});
    }
    _showListeningOverlay();

    // Lấy danh sách locale khả dụng
    final locales = await _speech.locales();
    String? selectedLocale;

    // Ưu tiên tiếng Việt, nếu không có thì dùng locale đầu tiên
    if (locales.isNotEmpty) {
      // Tìm locale tiếng Việt
      final viLocale = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('vi'),
        orElse: () => locales.first,
      );
      selectedLocale = viLocale.localeId;
      debugPrint(
        'Using locale: $selectedLocale (available: ${locales.length} locales)',
      );
    } else {
      debugPrint('No locales available, using default');
    }

    _speech.listen(
      localeId: selectedLocale, // Dùng locale khả dụng thay vì cố định
      listenFor: const Duration(seconds: 10), // Tăng từ 6s lên 10s
      pauseFor: const Duration(seconds: 2), // Tăng từ 1s lên 2s
      onResult: (result) {
        _voiceText = result.recognizedWords;
        if (mounted) {
          setState(() {});
        }
        _overlaySetState?.call(() {});
        if (result.finalResult) {
          // Dừng ghi âm trước, giữ overlay để người dùng bấm Lưu
          try {
            _speech.stop();
          } catch (_) {}
          _voiceTextFinal = result.recognizedWords;
          _hasFinalResult = true;
          _pendingParsedAlarm = _parseAlarmFromText(_voiceTextFinal);
          if (mounted) {
            setState(() {});
          }
          _overlaySetState?.call(() {});
        }
      },
      onSoundLevelChange: (level) {
        _soundLevel = level;
        _overlaySetState?.call(() {});
      },
    );
  }

  void _stopListening() {
    try {
      _speech.stop();
    } catch (_) {}
    try {
      _speech.cancel();
    } catch (_) {}
    _isListening = false;
    if (mounted) {
      setState(() {});
    }
    _hideListeningOverlay();
  }

  void _savePendingAlarm() {
    final al = _pendingParsedAlarm;
    if (al == null) return;
    _alarms.add(al);
    if (mounted) {
      setState(() {});
    }
    _hideListeningOverlay();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã đặt báo thức lúc ${al.time.format(context)}'),
        ),
      );
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPermissionRequestDialog() async {
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.blue),
            SizedBox(width: 12),
            Text('Cần quyền ghi âm'),
          ],
        ),
        content: const Text(
          'Ứng dụng cần quyền truy cập microphone để:\n\n'
          '• Nhận diện giọng nói\n'
          '• Đặt báo thức bằng giọng nói\n'
          '• Điều khiển ứng dụng bằng giọng nói\n\n'
          'Bạn có muốn cấp quyền không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cho phép'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPermissionDeniedDialog() async {
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Quyền bị từ chối'),
          ],
        ),
        content: const Text(
          'Bạn đã từ chối quyền ghi âm.\n\n'
          'Để sử dụng tính năng giọng nói, vui lòng:\n\n'
          '1. Mở Cài đặt ứng dụng\n'
          '2. Chọn "Quyền" hoặc "Permissions"\n'
          '3. Bật quyền "Microphone"\n\n'
          'Bạn có muốn mở Cài đặt không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }

  // Debug permission info
  void _showPermissionDebugInfo() async {
    final micStatus = await Permission.microphone.status;
    final speechAvailable = await _speech.initialize();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông tin quyền & khả năng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 Quyền Microphone: ${micStatus.toString()}'),
            Text(
              '🎤 Speech-to-Text: ${speechAvailable ? "Có hỗ trợ" : "Không hỗ trợ"}',
            ),
            const SizedBox(height: 8),
            const Text('Nếu có vấn đề:'),
            const Text('1. Vào Cài đặt > Ứng dụng > App này > Quyền'),
            const Text('2. Bật quyền Microphone'),
            const Text('3. Khởi động lại ứng dụng'),
          ],
        ),
        actions: [
          if (micStatus.isPermanentlyDenied)
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Mở Cài đặt'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Trả về AlarmModel nếu parse được, ngược lại null
  AlarmModel? _parseAlarmFromText(String raw) {
    if (raw.trim().isEmpty) return null;

    // -------- 1) Chuẩn hoá chuỗi --------
    String s = raw.toLowerCase();

    // Bỏ dấu ngoặc, zero-width, NBSP
    s = s
        .replaceAll(
          RegExp(
            r'["""'
            '`´\(\)\[\]]',
          ),
          '',
        )
        .replaceAll(RegExp(r'[\u00A0\u200B\u200C\u200D\uFEFF]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Bỏ từ đệm phổ biến
    s = s
        .replaceAll(
          RegExp(r'\b(báo thức|đặt|nhắc|nhắc nhở|cho|tôi|mình|vào|lúc|hãy)\b'),
          ' ',
        )
        .trim();

    // Chuẩn hoá "giờ" variations
    s = s.replaceAll(RegExp(r'\bgio\b'), 'giờ');

    // Chuẩn hoá dấu phân cách số -> ":" (8 30, 8.30, 8-30 → 8:30)
    s = s.replaceAllMapped(
      RegExp(r'(\d{1,2})\s*[\.\-]\s*(\d{1,2})'),
      (m) => '${m[1]}:${m[2]}',
    );

    // "rưỡi" → :30  (8 giờ rưỡi, 8h rưỡi, 8 rưỡi)
    s = s.replaceAllMapped(
      RegExp(r'(\d{1,2})\s*(?:giờ|h)?\s*r(?:u?ỡ|ươ)i'),
      (m) => '${m[1]}:30',
    );

    // "kém X phút" → giờ trước + (60-X) phút
    s = s.replaceAllMapped(
      RegExp(r'(\d{1,2})\s*(?:giờ|h)?\s*kém\s*(\d{1,2})(?:\s*phút)?'),
      (m) {
        int base = int.parse(m[1]!);
        int minus = int.parse(m[2]!);
        int h = (base - 1 + 24) % 24;
        int mm = (60 - minus) % 60;
        return '$h:${mm.toString().padLeft(2, '0')}';
      },
    );

    // -------- 2) Regex các mẫu phổ biến --------
    final periodRe = r'(sáng|trưa|chiều|tối|đêm|khuya)';
    final List<RegExp> patterns = [
      // Pattern 0: 8:30 [buổi] | 20:15 | 00:05 đêm
      RegExp(r'\b(\d{1,2}):(\d{1,2})\s*' + periodRe + r'?(?:\s|$)'),

      // Pattern 1: 8h30 [buổi] | 8 giờ 5 phút | 8h 5p | 8 giờ 5
      RegExp(
        r'\b(\d{1,2})\s*(?:giờ|h)\s*(\d{1,2})?\s*(?:phút|p)?\s*' +
            periodRe +
            r'?(?:\s|$)',
      ),

      // Pattern 2: 8 [buổi] | 20 giờ | 8 tối (có buổi)
      RegExp(r'\b(\d{1,2})\s*(?:giờ|h)?\s*' + periodRe + r'(?:\s|$)'),

      // Pattern 3: chỉ số giờ không có buổi (22 giờ, 15 giờ)
      RegExp(r'\b(\d{1,2})\s*(?:giờ|h)(?:\s|$)'),
    ];

    RegExpMatch? m;
    int usedPattern = -1;
    for (int i = 0; i < patterns.length; i++) {
      final t = patterns[i].firstMatch(s);
      if (t != null) {
        m = t;
        usedPattern = i;
        break;
      }
    }
    if (m == null) return null;

    int? hour = int.tryParse(m.group(1) ?? '');
    if (hour == null) return null;

    int minute = 0;
    String? period;

    // Parse phút và buổi theo từng pattern
    if (usedPattern == 0) {
      // H:M [buổi]
      minute = int.tryParse(m.group(2) ?? '0') ?? 0;
      period = m.group(3);
    } else if (usedPattern == 1) {
      // H giờ [M] [buổi]
      String? g2 = m.group(2);
      String? g3 = m.group(3);

      if (g2 != null && RegExp(r'^\d+$').hasMatch(g2)) {
        minute = int.tryParse(g2) ?? 0;
        period = g3;
      } else {
        period = g2;
      }
    } else if (usedPattern == 2) {
      // H [buổi]
      period = m.group(2);
    }

    // Validate phút
    if (minute < 0 || minute > 59) return null;

    // -------- 3) Xử lý AM/PM dựa trên buổi --------
    final per = (period ?? '').trim();

    // Nếu giờ đã ở dạng 24h (>= 13) và không có buổi -> giữ nguyên
    if (hour >= 13 && hour <= 23 && per.isEmpty) {
      // Đã là 24h format (22 giờ, 15 giờ...), giữ nguyên
    }
    // Nếu "sáng" mà giờ >= 13 -> có thể là nhầm, trừ 12
    else if (per.contains('sáng') && hour >= 13 && hour <= 23) {
      hour -= 12;
    }
    // Xử lý các buổi có chỉ định
    else if (per.isNotEmpty) {
      // Xử lý đặc biệt cho 12h
      if (hour == 12) {
        if (per.contains('đêm') || per.contains('khuya')) {
          // "12 đêm/khuya" = 0h (nửa đêm)
          hour = 0;
        } else if (per.contains('sáng')) {
          // "12 sáng" = 0h (nửa đêm)
          hour = 0;
        } else if (per.contains('trưa') || per.contains('chiều')) {
          // "12 trưa/chiều" = 12h (giữa trưa)
          hour = 12;
        } else if (per.contains('tối')) {
          // "12 tối" = 0h (nửa đêm)
          hour = 0;
        }
      }
      // Xử lý cho "trưa" (12h-14h, nhưng 1-11 trưa cũng hợp lệ)
      else if (per.contains('trưa')) {
        if (hour >= 1 && hour <= 11) {
          hour += 12; // 1-11 trưa -> 13-23h
        }
        // 12-14 trưa giữ nguyên nếu đã >= 12
      }
      // Xử lý PM cho chiều/tối/đêm/khuya
      else if (per.contains('chiều') ||
          per.contains('tối') ||
          per.contains('đêm') ||
          per.contains('khuya')) {
        if (hour >= 1 && hour <= 11) {
          hour += 12;
        }
      }
      // Xử lý "sáng"
      else if (per.contains('sáng')) {
        // 1-11 sáng giữ nguyên (AM)
        // 12 sáng đã xử lý ở trên
      }
    }

    // Validate giờ cuối cùng
    if (hour < 0 || hour > 23) return null;

    return AlarmModel(
      time: TimeOfDay(hour: hour, minute: minute),
      label: 'Báo thức bằng giọng nói',
      isActive: true,
      repeatDaily: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alarmChecker?.cancel();
    _audioPlayer.dispose();
    try {
      _speech.stop();
    } catch (_) {}
    try {
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đồng hồ báo thức'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.black54,
            ),
            onPressed: _isListening ? _stopListening : _startListening,
            tooltip: 'Đặt báo thức bằng giọng nói',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPermissionDebugInfo,
            tooltip: 'Kiểm tra quyền',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header: time now
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple[100]!, Colors.blue[100]!],
              ),
            ),
            child: Column(
              children: [
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (_, __) {
                    return Text(
                      TimeOfDay.now().format(context),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    );
                  },
                ),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Toolbar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Báo thức (${_alarms.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addAlarm,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _alarms.isEmpty
                ? const _EmptyAlarms()
                : ListView.builder(
                    itemCount: _alarms.length,
                    itemBuilder: (_, i) {
                      final a = _alarms[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Icon(
                            a.isActive ? Icons.alarm : Icons.alarm_off,
                            color: a.isActive ? Colors.green : Colors.grey,
                            size: 28,
                          ),
                          title: Text(
                            a.time.format(context),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: a.isActive ? Colors.black : Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            [
                              a.label.isEmpty ? 'Báo thức' : a.label,
                              if (a.repeatDaily) 'Lặp hằng ngày',
                            ].join(' • '),
                            style: TextStyle(
                              color: a.isActive
                                  ? Colors.grey[700]
                                  : Colors.grey,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: a.isActive,
                                onChanged: (_) => _toggleAlarm(i),
                              ),
                              IconButton(
                                onPressed: () => _deleteAlarm(i),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Test sound
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _playAlarmSound();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đang phát âm báo…')),
                          );
                        },
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Thử âm báo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _stopAlarmSound,
                        icon: const Icon(Icons.stop),
                        label: const Text('Dừng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlarms extends StatelessWidget {
  const _EmptyAlarms();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có báo thức nào',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Nhấn "Thêm" để tạo báo thức mới',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CreateAlarmInfo {
  final String label;
  final bool repeatDaily;
  _CreateAlarmInfo(this.label, this.repeatDaily);
}

class AlarmModel {
  TimeOfDay time;
  String label;
  bool isActive;
  bool repeatDaily;
  String? lastTriggeredKey;

  AlarmModel({
    required this.time,
    required this.label,
    required this.isActive,
    this.repeatDaily = true,
    this.lastTriggeredKey,
  });

  String triggerKeyFor(DateTime dt) =>
      '${dt.year}-${dt.month}-${dt.day} ${time.hour}:${time.minute}';
}
