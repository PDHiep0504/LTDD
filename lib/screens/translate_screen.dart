import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({Key? key}) : super(key: key);

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final GoogleTranslator _translator = GoogleTranslator();
  final ImagePicker _picker = ImagePicker();
  late TextRecognizer _textRecognizer;
  late OnDeviceTranslator _onDeviceTranslator;
  stt.SpeechToText _speech = stt.SpeechToText();

  TabController? _tabController;
  String _translatedText = '';
  String _selectedFromLanguage = 'vi';
  String _selectedToLanguage = 'en';
  bool _isTranslating = false;
  bool _isListening = false;
  File? _selectedImage;
  String _extractedText = '';

  final Map<String, String> _languages = {
    'vi': 'Tiếng Việt',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'zh': '中文',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'th': 'ไทย',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMLKit();
  }

  void _initializeMLKit() async {
    _textRecognizer = TextRecognizer();
    _onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == _selectedFromLanguage,
        orElse: () => TranslateLanguage.vietnamese,
      ),
      targetLanguage: TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == _selectedToLanguage,
        orElse: () => TranslateLanguage.english,
      ),
    );
  }

  Future<void> _translateText(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final translation = await _translator.translate(
        text,
        from: _selectedFromLanguage,
        to: _selectedToLanguage,
      );

      setState(() {
        _translatedText = translation.text;
      });
    } catch (e) {
      _showErrorDialog('Lỗi dịch', 'Không thể dịch văn bản: $e');
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
          if (result.finalResult) {
            _translateText(_textController.text);
            _stopListening();
          }
        },
        localeId: _selectedFromLanguage == 'vi' ? 'vi_VN' : 'en_US',
      );
    } else {
      _showErrorDialog('Lỗi', 'Không thể khởi tạo speech-to-text');
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedText = '';
        });
        await _extractTextFromImage();
      }
    } catch (e) {
      _showErrorDialog('Lỗi', 'Không thể chọn ảnh: $e');
    }
  }

  Future<void> _extractTextFromImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final inputImage = InputImage.fromFile(_selectedImage!);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      setState(() {
        _extractedText = recognizedText.text;
        _textController.text = _extractedText;
      });

      if (_extractedText.isNotEmpty) {
        await _translateText(_extractedText);
      }
    } catch (e) {
      _showErrorDialog('Lỗi', 'Không thể nhận diện văn bản từ ảnh: $e');
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageSelector(
    String label,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: _languages.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextTranslateTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language Selectors
          Row(
            children: [
              Expanded(
                child: _buildLanguageSelector(
                  'Từ',
                  _selectedFromLanguage,
                  (value) => setState(() => _selectedFromLanguage = value!),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  setState(() {
                    final temp = _selectedFromLanguage;
                    _selectedFromLanguage = _selectedToLanguage;
                    _selectedToLanguage = temp;
                  });
                },
                icon: const Icon(Icons.swap_horiz),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLanguageSelector(
                  'Đến',
                  _selectedToLanguage,
                  (value) => setState(() => _selectedToLanguage = value!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Input Text
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Nhập văn bản cần dịch...',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Translate Button
          ElevatedButton.icon(
            onPressed: _isTranslating
                ? null
                : () => _translateText(_textController.text),
            icon: _isTranslating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate),
            label: Text(_isTranslating ? 'Đang dịch...' : 'Dịch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 20),

          // Translated Text
          if (_translatedText.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kết quả dịch:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _translatedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceTranslateTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language Selectors
          Row(
            children: [
              Expanded(
                child: _buildLanguageSelector(
                  'Từ',
                  _selectedFromLanguage,
                  (value) => setState(() => _selectedFromLanguage = value!),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  setState(() {
                    final temp = _selectedFromLanguage;
                    _selectedFromLanguage = _selectedToLanguage;
                    _selectedToLanguage = temp;
                  });
                },
                icon: const Icon(Icons.swap_horiz),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLanguageSelector(
                  'Đến',
                  _selectedToLanguage,
                  (value) => setState(() => _selectedToLanguage = value!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Voice Input
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red : Colors.blue,
                      boxShadow: [
                        if (_isListening)
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isListening ? 'Đang nghe...' : 'Nhấn để nói',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Recognized Text
          if (_textController.text.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Văn bản nhận diện:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_textController.text),
                  ],
                ),
              ),
            ),

          // Translated Text
          if (_translatedText.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kết quả dịch:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _translatedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageTranslateTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language Selectors
          Row(
            children: [
              Expanded(
                child: _buildLanguageSelector(
                  'Từ',
                  _selectedFromLanguage,
                  (value) => setState(() => _selectedFromLanguage = value!),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  setState(() {
                    final temp = _selectedFromLanguage;
                    _selectedFromLanguage = _selectedToLanguage;
                    _selectedToLanguage = temp;
                  });
                },
                icon: const Icon(Icons.swap_horiz),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLanguageSelector(
                  'Đến',
                  _selectedToLanguage,
                  (value) => setState(() => _selectedToLanguage = value!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Camera and Image Options
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp ảnh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Chọn ảnh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Selected Image
          if (_selectedImage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ảnh đã chọn:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _extractedText = '';
                              _translatedText = '';
                            });
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Extracted Text
          if (_extractedText.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Văn bản trích xuất:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: SelectableText(
                        _extractedText,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Translated Text
          if (_translatedText.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kết quả dịch:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: SelectableText(
                        _translatedText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading Indicator
          if (_isTranslating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang nhận diện và dịch văn bản...'),
                  ],
                ),
              ),
            ),

          // Instructions
          if (_selectedImage == null && !_isTranslating)
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hướng dẫn sử dụng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Chụp ảnh hoặc chọn ảnh có chứa văn bản\n'
                      '2. Ứng dụng sẽ tự động nhận diện văn bản\n'
                      '3. Văn bản sẽ được dịch sang ngôn ngữ đã chọn\n'
                      '4. Bạn có thể sao chép kết quả dịch',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.left,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch thuật'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.text_fields), text: 'Văn bản'),
            Tab(icon: Icon(Icons.mic), text: 'Giọng nói'),
            Tab(icon: Icon(Icons.image), text: 'Hình ảnh'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTextTranslateTab(),
          _buildVoiceTranslateTab(),
          _buildImageTranslateTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _tabController?.dispose();
    _textRecognizer.close();
    _onDeviceTranslator.close();
    super.dispose();
  }
}
