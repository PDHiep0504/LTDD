import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:permission_handler/permission_handler.dart';

class TranslatedText {
  final String originalText;
  final String translatedText;
  final DateTime timestamp;
  
  TranslatedText({
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
  });
}

class CameraTranslateScreen extends StatefulWidget {
  const CameraTranslateScreen({Key? key}) : super(key: key);

  @override
  State<CameraTranslateScreen> createState() => _CameraTranslateScreenState();
}

class _CameraTranslateScreenState extends State<CameraTranslateScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // ML Kit
  final TextRecognizer _textRecognizer = TextRecognizer();
  OnDeviceTranslator? _translator;

  // Translation settings
  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage _targetLanguage = TranslateLanguage.vietnamese;

  // Detected texts and translations
  List<TextElement> _textElements = [];
  Map<String, String> _translations = {};
  List<TranslatedText> _translationHistory = [];
  
  // Current full text detection
  String _currentFullText = '';
  String _currentTranslation = '';
  DateTime? _lastDetectionTime;

  // Timer for continuous detection
  Timer? _detectionTimer;
  bool _isRealTimeMode = true;
  
  // UI State
  bool _showTranslationPanel = false;
  final ScrollController _scrollController = ScrollController();
  bool _showTextView = false; // Toggle between camera view and text view

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeTranslator();

    // Force landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    _textRecognizer.close();
    _translator?.close();
    _scrollController.dispose();

    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần quyền truy cập camera')),
      );
      return;
    }

    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
        _startRealTimeDetection();
      } catch (e) {
        print('Lỗi khởi tạo camera: $e');
      }
    }
  }

  Future<void> _initializeTranslator() async {
    try {
      _translator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
    } catch (e) {
      print('Lỗi khởi tạo translator: $e');
    }
  }

  void _startRealTimeDetection() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      if (_isRealTimeMode && !_isProcessing && _isCameraInitialized) {
        _detectAndTranslateText();
      }
    });
  }

  Future<void> _detectAndTranslateText() async {
    if (_isProcessing || _cameraController?.value.isInitialized != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Combine all detected text into one string
      List<String> allTextLines = [];
      List<TextElement> newTextElements = [];

      for (TextBlock block in recognizedText.blocks) {
        List<String> blockLines = [];
        for (TextLine line in block.lines) {
          List<String> lineWords = [];
          for (TextElement element in line.elements) {
            if (element.text.trim().isNotEmpty) {
              newTextElements.add(element);
              lineWords.add(element.text.trim());
            }
          }
          if (lineWords.isNotEmpty) {
            blockLines.add(lineWords.join(' '));
          }
        }
        if (blockLines.isNotEmpty) {
          allTextLines.addAll(blockLines);
        }
      }

      final fullText = allTextLines.join(' ').trim();
      
      // Only translate if we have new text or significant changes
      if (fullText.isNotEmpty && fullText != _currentFullText) {
        try {
          final translation = await _translator?.translateText(fullText);
          if (translation != null && translation.isNotEmpty) {
            
            // Update current states
            _currentFullText = fullText;
            _currentTranslation = translation;
            _lastDetectionTime = DateTime.now();
            
            // Add to history as a single entry
            final existingIndex = _translationHistory.indexWhere(
              (item) => item.originalText == fullText
            );
            
            if (existingIndex == -1) {
              // Add new translation to history
              _translationHistory.add(TranslatedText(
                originalText: fullText,
                translatedText: translation,
                timestamp: DateTime.now(),
              ));
            } else {
              // Update existing translation timestamp
              _translationHistory[existingIndex] = TranslatedText(
                originalText: fullText,
                translatedText: translation,
                timestamp: DateTime.now(),
              );
            }
            
            // Keep only latest 20 translations to avoid memory issues
            if (_translationHistory.length > 20) {
              _translationHistory = _translationHistory.sublist(_translationHistory.length - 20);
            }
          }
        } catch (e) {
          print('Lỗi dịch: $e');
        }
      }

      setState(() {
        _textElements = newTextElements;
      });

      // Clean up temp image
      File(image.path).delete();
    } catch (e) {
      print('Lỗi detect text: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _switchLanguages() async {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;

    _translator?.close();
    await _initializeTranslator();

    setState(() {
      _translations.clear();
      _textElements.clear();
      _translationHistory.clear();
      _currentFullText = '';
      _currentTranslation = '';
      _lastDetectionTime = null;
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}p trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h trước';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _copyAllTranslations() {
    if (_translationHistory.isEmpty) return;
    
    final buffer = StringBuffer();
    for (int i = 0; i < _translationHistory.length; i++) {
      final item = _translationHistory[i];
      buffer.writeln('${i + 1}. ${item.originalText}');
      buffer.writeln('   → ${item.translatedText}');
      buffer.writeln();
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã sao chép ${_translationHistory.length} bản dịch'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content area - either camera or text view
          if (_showTextView) 
            _buildTextView()
          else
            _buildCameraView(),



          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),

                // Language selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getLanguageName(_sourceLanguage),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        onPressed: _switchLanguages,
                        icon: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        constraints: const BoxConstraints(),
                      ),
                      Text(
                        _getLanguageName(_targetLanguage),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Real-time toggle
                Container(
                  decoration: BoxDecoration(
                    color: _isRealTimeMode ? Colors.blue : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isRealTimeMode = !_isRealTimeMode;
                        if (_isRealTimeMode) {
                          _startRealTimeDetection();
                        } else {
                          _detectionTimer?.cancel();
                        }
                      });
                    },
                    icon: Icon(
                      _isRealTimeMode ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),

                // View toggle (Camera/Text)
                Tooltip(
                  message: _showTextView ? 'Chuyển về Camera' : 'Xem Kết quả Dịch',
                  child: Container(
                    decoration: BoxDecoration(
                      color: _showTextView ? Colors.green : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showTextView = !_showTextView;
                        });
                      },
                      icon: Icon(
                        _showTextView ? Icons.videocam : Icons.text_fields,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Manual capture (only show in camera view)
                if (!_showTextView)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      onPressed: _isProcessing ? null : _detectAndTranslateText,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),

                // Translation history panel toggle (only in camera view)
                if (!_showTextView)
                  Container(
                    decoration: BoxDecoration(
                      color: _showTranslationPanel ? Colors.blue : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showTranslationPanel = !_showTranslationPanel;
                        });
                      },
                      icon: Icon(
                        _showTranslationPanel ? Icons.list_alt : Icons.history,
                        color: Colors.white,
                      ),
                    ),
                  ),
                
                // Clear translations
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _translations.clear();
                        _textElements.clear();
                        _translationHistory.clear();
                        _currentFullText = '';
                        _currentTranslation = '';
                        _lastDetectionTime = null;
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đang dịch...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Translation History Panel (only show in camera view)
          if (!_showTextView)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: _showTranslationPanel ? 0 : -MediaQuery.of(context).size.width * 0.4,
              top: MediaQuery.of(context).padding.top + 80,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                border: Border.all(color: Colors.blue, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
                child: Column(
                  children: [
                    // Panel Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(19),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.translate, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Văn bản đã dịch',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${_translationHistory.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (_translationHistory.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _copyAllTranslations,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.copy, color: Colors.white, size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            'Copy tất cả',
                                            style: TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _translationHistory.clear();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.white, size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            'Xóa tất cả',
                                            style: TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Translation List
                    Expanded(
                      child: _translationHistory.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Chưa có văn bản nào được dịch.\n\nHướng camera vào văn bản để bắt đầu dịch.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: _translationHistory.length,
                              reverse: true, // Show latest first
                              itemBuilder: (context, index) {
                                final item = _translationHistory[_translationHistory.length - 1 - index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Original text
                                                Text(
                                                  item.originalText,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                // Translation
                                                Text(
                                                  item.translatedText,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Copy button
                                          GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(
                                                text: '${item.originalText}\n→ ${item.translatedText}'
                                              ));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('✅ Đã sao chép'),
                                                  backgroundColor: Colors.green,
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                Icons.copy,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Timestamp
                                      Text(
                                        _formatTime(item.timestamp),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

          // Real-time translation counter
          if (_isRealTimeMode && _translationHistory.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              right: _showTranslationPanel ? MediaQuery.of(context).size.width * 0.4 + 20 : 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Realtime: ${_translationHistory.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera preview
        if (_isCameraInitialized)
          Positioned.fill(child: CameraPreview(_cameraController!))
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Current translation overlay (bottom area)
        if (_currentTranslation.isNotEmpty)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 120,
            left: 20,
            right: _showTranslationPanel ? MediaQuery.of(context).size.width * 0.4 + 20 : 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with language info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.translate, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_getLanguageName(_sourceLanguage)} → ${_getLanguageName(_targetLanguage)}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_lastDetectionTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Original text (smaller)
                  if (_currentFullText.isNotEmpty) ...[
                    Text(
                      'Văn bản gốc:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentFullText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Translation (prominent)
                  Text(
                    'Bản dịch:',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.4)),
                    ),
                    child: Text(
                      _currentTranslation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _currentTranslation));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Đã sao chép bản dịch'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.copy, color: Colors.blue, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Sao chép',
                                  style: TextStyle(color: Colors.blue, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showTextView = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.text_fields, color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Xem tất cả',
                                  style: TextStyle(color: Colors.green, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Detection area indicator
        if (_isCameraInitialized && _currentFullText.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.blue, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    _isRealTimeMode ? 'Hướng camera vào văn bản' : 'Tap nút chụp để dịch',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Văn bản sẽ được dịch tự động',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextView() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.blue.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                const Icon(Icons.text_fields, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kết quả dịch Realtime',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_translationHistory.length} đoạn văn đã dịch',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isRealTimeMode) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Translation list
          Expanded(
            child: _translationHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 64, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có đoạn văn nào được dịch',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chuyển về chế độ Camera và hướng vào văn bản\nđể dịch toàn bộ đoạn văn một lần',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _translationHistory.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final item = _translationHistory[_translationHistory.length - 1 - index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with timestamp and copy button
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatTime(item.timestamp),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                      text: '${item.originalText}\n→ ${item.translatedText}'
                                    ));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Đã sao chép'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, color: Colors.blue),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Original text
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Văn bản gốc (${_getLanguageName(_sourceLanguage)}):',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.originalText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Translated text
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bản dịch (${_getLanguageName(_targetLanguage)}):',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.translatedText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(TranslateLanguage language) {
    switch (language) {
      case TranslateLanguage.english:
        return 'EN';
      case TranslateLanguage.vietnamese:
        return 'VI';
      case TranslateLanguage.chinese:
        return 'ZH';
      case TranslateLanguage.japanese:
        return 'JA';
      case TranslateLanguage.korean:
        return 'KO';
      case TranslateLanguage.french:
        return 'FR';
      case TranslateLanguage.german:
        return 'DE';
      case TranslateLanguage.spanish:
        return 'ES';
      default:
        return language.name.toUpperCase();
    }
  }
}

class TextOverlayPainter extends CustomPainter {
  final List<TextElement> textElements;
  final Map<String, String> translations;
  final CameraController cameraController;

  TextOverlayPainter({
    required this.textElements,
    required this.translations,
    required this.cameraController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final element in textElements) {
      final translation = translations[element.text];
      if (translation != null && translation.isNotEmpty) {
        // Convert ML Kit coordinates to screen coordinates
        final rect = _convertBoundingBox(element.boundingBox, size);

        // Draw background
        final RRect backgroundRect = RRect.fromRectAndRadius(
          rect.inflate(8),
          const Radius.circular(4),
        );
        canvas.drawRRect(backgroundRect, backgroundPaint);
        canvas.drawRRect(backgroundRect, borderPaint);

        // Draw original text (smaller, top)
        final originalTextPainter = TextPainter(
          text: TextSpan(
            text: element.text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        originalTextPainter.layout(maxWidth: rect.width + 16);
        originalTextPainter.paint(canvas, Offset(rect.left - 8, rect.top - 8));

        // Draw translation (larger, bottom)
        final translationTextPainter = TextPainter(
          text: TextSpan(
            text: translation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        translationTextPainter.layout(maxWidth: rect.width + 16);
        translationTextPainter.paint(
          canvas,
          Offset(rect.left - 8, rect.top + originalTextPainter.height - 4),
        );
      }
    }
  }

  Rect _convertBoundingBox(Rect boundingBox, Size screenSize) {
    if (!cameraController.value.isInitialized) return Rect.zero;

    // Get camera preview size
    final cameraSize = cameraController.value.previewSize!;

    // Calculate scale factors
    final double scaleX = screenSize.width / cameraSize.height;
    final double scaleY = screenSize.height / cameraSize.width;

    // Convert coordinates (camera is rotated 90 degrees)
    return Rect.fromLTRB(
      boundingBox.top * scaleX,
      boundingBox.left * scaleY,
      boundingBox.bottom * scaleX,
      boundingBox.right * scaleY,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
