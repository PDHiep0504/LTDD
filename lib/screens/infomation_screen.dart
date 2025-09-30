import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class InformationScreen extends StatefulWidget {
  const InformationScreen({Key? key}) : super(key: key);

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  YoutubePlayerController? _controller;
  TextEditingController _urlController = TextEditingController();
  bool _isPlayerReady = false;
  String _errorMessage = '';
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    // Load a default video
    _loadVideo('dQw4w9WgXcQ'); // Rick Roll as default
  }

  void _loadVideo(String videoId) {
    if (videoId.isEmpty) return;

    // Tạo 1 lần
    if (_controller == null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false, // tắt caption để nhanh hơn
          forceHD: false, // tránh ép HD, giảm thời gian vào
        ),
      );
      setState(() {
        _isPlayerReady = true;
        _errorMessage = '';
      });
    } else {
      // Tải video mới NHANH hơn, không rebuild WebView
      _controller!.load(videoId);
      setState(() {
        _errorMessage = '';
      });
    }
  }

  void _loadVideoFromUrl() {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập link YouTube';
      });
      return;
    }

    String? videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      setState(() {
        _errorMessage =
            'Link YouTube không hợp lệ. Vui lòng nhập link đúng định dạng.';
      });
      return;
    }

    _loadVideo(videoId);
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceText = result.recognizedWords;
            _urlController.text = _voiceText;
            _loadVideoFromUrl();
          });
        },
        localeId: 'vi_VN',
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Player'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // URL Input Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nhập link YouTube:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              decoration: const InputDecoration(
                                hintText: 'https://www.youtube.com/watch?v=...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.link),
                              ),
                              onSubmitted: (value) => _loadVideoFromUrl(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.red,
                            ),
                            onPressed: _isListening
                                ? _stopListening
                                : _startListening,
                            tooltip: 'Nhập link bằng giọng nói',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loadVideoFromUrl,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Phát video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              _urlController.clear();
                              setState(() {
                                _errorMessage = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Xóa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Video Player Section
              if (_isPlayerReady && _controller != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        YoutubePlayer(
                          controller: _controller!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: Colors.red,
                          progressColors: const ProgressBarColors(
                            playedColor: Colors.red,
                            handleColor: Colors.redAccent,
                          ),
                          onReady: () {
                            print('Player is ready.');
                          },
                        ),
                        const SizedBox(height: 12),
                        // Video Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.replay_10),
                              onPressed: () {
                                _controller!.seekTo(
                                  Duration(
                                    seconds:
                                        _controller!.value.position.inSeconds -
                                        10,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _controller!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: () {
                                if (_controller!.value.isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10),
                              onPressed: () {
                                _controller!.seekTo(
                                  Duration(
                                    seconds:
                                        _controller!.value.position.inSeconds +
                                        10,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Quick Links Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Video mẫu:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickLinkButton(
                        'Relaxing Music',
                        'jfKfPfyJRdk',
                        Icons.music_note,
                        Colors.purple,
                      ),
                      const SizedBox(height: 8),
                      _buildQuickLinkButton(
                        'Nature Sounds',
                        '36YnV9STBqc',
                        Icons.nature,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildQuickLinkButton(
                        'Coding Tutorial',
                        'Oe421EPjeBE',
                        Icons.code,
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Instructions
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Hướng dẫn sử dụng:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Nhập link YouTube vào ô trên\n'
                        '• Nhấn "Phát video" để xem\n'
                        '• Sử dụng các nút điều khiển để tua video\n'
                        '• Chọn video mẫu để xem nhanh',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLinkButton(
    String title,
    String videoId,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _loadVideo(videoId),
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _urlController.dispose();
    super.dispose();
  }
}
