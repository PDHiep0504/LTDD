import 'package:flutter/material.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({Key? key}) : super(key: key);

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Timer? _autoStopTimer;
  List<String> _lapTimes = [];
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {});
      }
    });
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();

    String hoursStr = (hours % 60).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');

    if (hours > 0) {
      return "$hoursStr:$minutesStr:$secondsStr.$hundredsStr";
    } else {
      return "$minutesStr:$secondsStr.$hundredsStr";
    }
  }

  void _startStop() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    } else {
      _stopwatch.start();
    }
    setState(() {});
  }

  void _reset() {
    _stopwatch.reset();
    _lapTimes.clear();
    setState(() {});
  }

  void _lap() {
    if (_stopwatch.isRunning) {
      String lapTime = _formatTime(_stopwatch.elapsedMilliseconds);
      _lapTimes.insert(0, 'Lap ${_lapTimes.length + 1}: $lapTime');
      setState(() {});
    }
  }

  void _startListening() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Không thể ghi âm'),
            content: const Text('Thiết bị không hỗ trợ hoặc bạn chưa cấp quyền ghi âm.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
          ),
        );
        return;
      }
    }
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceText = result.recognizedWords;
            _handleVoiceCommand(_voiceText);
          });
        },
        localeId: 'vi_VN',
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Không thể ghi âm'),
          content: const Text('Thiết bị không hỗ trợ hoặc chưa cấp quyền ghi âm.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
        ),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _handleVoiceCommand(String text) {
    final lower = text.toLowerCase();
    final regexMinute = RegExp(r'(đặt giờ|set timer)\s*(\d+)\s*(phút|minutes?)');
    final regexSecond = RegExp(r'(đặt giờ|set timer)\s*(\d+)\s*(giây|seconds?)');
    var matchMinute = regexMinute.firstMatch(lower);
    var matchSecond = regexSecond.firstMatch(lower);
    if (matchMinute != null) {
      int minutes = int.parse(matchMinute.group(2)!);
      _setTimer(Duration(minutes: minutes));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đặt giờ bấm ${minutes} phút')),
      );
    } else if (matchSecond != null) {
      int seconds = int.parse(matchSecond.group(2)!);
      _setTimer(Duration(seconds: seconds));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đặt giờ bấm ${seconds} giây')),
      );
    } else if (lower.contains('bắt đầu') || lower.contains('start')) {
      if (!_stopwatch.isRunning) _startStop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã bắt đầu bấm giờ')));
    } else if (lower.contains('dừng') || lower.contains('stop') || lower.contains('pause')) {
      _autoStopTimer?.cancel();
      if (_stopwatch.isRunning) _startStop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã dừng bấm giờ')));
    } else if (lower.contains('reset') || lower.contains('làm lại')) {
      _autoStopTimer?.cancel();
      _reset();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã reset đồng hồ')));
    } else if (lower.contains('lap') || lower.contains('ghi lại') || lower.contains('ghi thời gian')) {
      _lap();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã ghi lại thời gian')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không nhận diện được lệnh!')));
    }
    _stopListening();
  }
  void _setTimer(Duration duration) {
    _stopwatch.reset();
    _stopwatch.start();
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(duration, () {
      _stopwatch.stop();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hết thời gian bấm giờ!')),
      );
    });
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đồng hồ bấm giờ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.red),
            onPressed: _isListening ? _stopListening : _startListening,
            tooltip: 'Điều khiển bằng giọng nói',
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer Display
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[50]!, Colors.white],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main timer display
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(77),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _formatTime(_stopwatch.elapsedMilliseconds),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: _stopwatch.isRunning ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _stopwatch.isRunning ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _stopwatch.isRunning ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _stopwatch.isRunning ? 'Đang chạy' : 'Đã dừng',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control Buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reset Button
                ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Reset', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),

                // Start/Stop Button
                ElevatedButton(
                  onPressed: _startStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stopwatch.isRunning ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(
                        _stopwatch.isRunning ? 'Dừng' : 'Bắt đầu',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Lap Button
                ElevatedButton(
                  onPressed: _stopwatch.isRunning ? _lap : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag),
                      SizedBox(width: 8),
                      Text('Lap', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lap Times List
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.list, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Lap Times (${_lapTimes.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _lapTimes.isEmpty
                        ? const Center(
                            child: Text(
                              'Nhấn "Lap" để ghi lại thời gian',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _lapTimes.length,
                            itemBuilder: (context, index) {
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      '${_lapTimes.length - index}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    _lapTimes[index],
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                    ),
                                  ),
                                  trailing: index == 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Mới nhất',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoStopTimer?.cancel();
    super.dispose();
  }
}
