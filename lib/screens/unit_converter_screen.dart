import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({Key? key}) : super(key: key);

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  String _selectedCategory = 'Nhiệt độ';
  String _fromUnit = 'Celsius';
  String _toUnit = 'Fahrenheit';
  final TextEditingController _inputController = TextEditingController();
  String _result = '';
  String _message = '';

  // Gốc quy đổi: °C cho nhiệt độ, mét cho độ dài, kg cho khối lượng
  final Map<String, Map<String, dynamic>> _conversions = {
    'Nhiệt độ': {
      'units': {
        'Celsius': {'symbol': '°C', 'color': Colors.blue},
        'Fahrenheit': {'symbol': '°F', 'color': Colors.red},
        'Kelvin': {'symbol': 'K', 'color': Colors.green},
      },
      'toBase': (double v, String from) {
        if (from == 'Fahrenheit') return (v - 32) * 5 / 9; // → °C
        if (from == 'Kelvin') return v - 273.15;           // → °C
        return v; // Celsius
      },
      'fromBase': (double c, String to) {
        if (to == 'Fahrenheit') return c * 9 / 5 + 32;
        if (to == 'Kelvin') return c + 273.15;
        return c; // Celsius
      },
    },
    'Độ dài': {
      'units': {
        'Mét': {'symbol': 'm', 'color': Colors.blue},
        'Kilômét': {'symbol': 'km', 'color': Colors.green},
        'Centimet': {'symbol': 'cm', 'color': Colors.orange},
        'Inch': {'symbol': 'in', 'color': Colors.purple},
      },
      'toBase': (double v, String from) {
        if (from == 'Kilômét') return v * 1000;      // → m
        if (from == 'Centimet') return v / 100;      // → m
        if (from == 'Inch') return v * 0.0254;       // → m
        return v; // Mét
      },
      'fromBase': (double m, String to) {
        if (to == 'Kilômét') return m / 1000;
        if (to == 'Centimet') return m * 100;
        if (to == 'Inch') return m / 0.0254;
        return m; // Mét
      },
    },
    'Khối lượng': {
      'units': {
        'Kilôgam': {'symbol': 'kg', 'color': Colors.blue},
        'Gam': {'symbol': 'g', 'color': Colors.green},
        'Pound': {'symbol': 'lb', 'color': Colors.red},
        'Ounce': {'symbol': 'oz', 'color': Colors.orange},
      },
      'toBase': (double v, String from) {
        if (from == 'Gam') return v / 1000;        // → kg
        if (from == 'Pound') return v * 0.453592;  // → kg
        if (from == 'Ounce') return v * 0.0283495; // → kg
        return v; // Kilôgam
      },
      'fromBase': (double kg, String to) {
        if (to == 'Gam') return kg * 1000;
        if (to == 'Pound') return kg / 0.453592;
        if (to == 'Ounce') return kg / 0.0283495;
        return kg; // Kilôgam
      },
    },
  };

  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    _updateUnits();
  }

  void _updateUnits() {
    final units = (_conversions[_selectedCategory]!['units'] as Map<String, Map<String, dynamic>>).keys.toList();
    _fromUnit = units.first;
    _toUnit = units.length > 1 ? units[1] : units.first;
    _convert();
  }

  double? _parse(String raw) {
    if (raw.trim().isEmpty) return null;
    // Hỗ trợ nhập "1,5" hoặc "1.5"
    final s = raw.replaceAll(',', '.');
    return double.tryParse(s);
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceText = result.recognizedWords;
            _inputController.text = _voiceText.replaceAll(RegExp(r'[^0-9.,-]'), '');
            _convert();
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

  void _convert() {
    final raw = _inputController.text;

    if (raw.isEmpty) {
      setState(() {
        _result = '';
        _message = 'Vui lòng nhập giá trị hoặc dùng giọng nói.';
      });
      return;
    }

    final value = _parse(raw);

    if (value == null) {
      setState(() {
        _result = '';
        _message = 'Vui lòng nhập số (hỗ trợ cả dấu , hoặc .)';
      });
      return;
    }

    // Ràng buộc vật lý & thông điệp lỗi sớm
    if (_selectedCategory == 'Nhiệt độ') {
      // Kelvin không thể âm
      if (_fromUnit == 'Kelvin' && value < 0) {
        setState(() {
          _result = '';
          _message = 'Giá trị Kelvin không thể nhỏ hơn 0 K.';
        });
        return;
      }
    } else if (_selectedCategory == 'Độ dài' || _selectedCategory == 'Khối lượng') {
      if (value < 0) {
        setState(() {
          _result = '';
          _message = 'Giá trị không thể âm cho loại chuyển đổi này.';
        });
        return;
      }
    }

    try {
      double value = double.parse(_inputController.text.replaceAll(',', '.'));
      double base = _conversions[_selectedCategory]!['toBase'](value, _fromUnit);
      double converted = _conversions[_selectedCategory]!['fromBase'](base, _toUnit);

      final units = _conversions[_selectedCategory]!['units'] as Map<String, Map<String, dynamic>>;

      final toSymbol = units[_toUnit]!['symbol'];
      final fromSymbol = units[_fromUnit]!['symbol'];

      setState(() {
        _result = '${converted.toStringAsFixed(2)} ${units[_toUnit]!['symbol']}';
        _message = _getConversionMessage(value, converted, _selectedCategory);
      });
    } catch (e) {
      setState(() {
        _result = '';
        _message = 'Giá trị không hợp lệ. Vui lòng nhập số hoặc dùng giọng nói.';
      });
    }
  }

  String _getConversionMessage(double fromValue, double toValue, String category) {
    // Thông điệp tùy chỉnh cho từng loại chuyển đổi
    switch (category) {
      case 'Nhiệt độ':
        return 'Đã chuyển đổi $fromValue° từ $_fromUnit sang $_toUnit: $toValue°';
      case 'Độ dài':
        return 'Đã chuyển đổi $fromValue từ $_fromUnit sang $_toUnit: $toValue';
      case 'Khối lượng':
        return 'Đã chuyển đổi $fromValue từ $_fromUnit sang $_toUnit: $toValue';
      default:
        return 'Đã chuyển đổi $fromValue từ $_fromUnit sang $_toUnit: $toValue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = _conversions[_selectedCategory]!['units'] as Map<String, Map<String, dynamic>>;
    final fromColor = units[_fromUnit]!['color'] as Color;
    final toColor = units[_toUnit]!['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển đổi đơn vị'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Loại chuyển đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _conversions.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedCategory = v!;
                        _updateUnits();
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedCategory == 'Nhiệt độ'
                        ? 'Quy đổi giữa °C, °F, K. Lưu ý: Kelvin không thể âm.'
                        : _selectedCategory == 'Độ dài'
                        ? 'Độ dài không âm. Quy đổi giữa m, km, cm, inch.'
                        : 'Khối lượng không âm. Quy đổi giữa kg, g, lb, oz.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Input + units
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Nhập giá trị',
                              border: const OutlineInputBorder(),
                              suffixText: units[_fromUnit]!['symbol'],
                            ),
                            onChanged: (value) => _convert(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.red),
                          onPressed: _isListening ? _stopListening : _startListening,
                          tooltip: 'Nhập giá trị bằng giọng nói',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: _UnitDropdown(
                          value: _fromUnit,
                          units: units,
                          label: 'Từ',
                          onChanged: (v) {
                            setState(() {
                              _fromUnit = v!;
                              _convert();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        tooltip: 'Đảo chiều',
                        onPressed: () {
                          setState(() {
                            final tmp = _fromUnit;
                            _fromUnit = _toUnit;
                            _toUnit = tmp;
                            _convert();
                          });
                        },
                        icon: const Icon(Icons.swap_horiz),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _UnitDropdown(
                          value: _toUnit,
                          units: units,
                          label: 'Sang',
                          onChanged: (v) {
                            setState(() {
                              _toUnit = v!;
                              _convert();
                            });
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    // Chips màu theo đơn vị
                    Row(
                      children: [
                        Chip(label: Text(_fromUnit), backgroundColor: fromColor.withOpacity(.1)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                        const SizedBox(width: 8),
                        Chip(label: Text(_toUnit), backgroundColor: toColor.withOpacity(.1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Result + message
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kết quả:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _result.isEmpty ? 'Chưa có kết quả' : _result,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _result.isEmpty ? Colors.grey : Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({
    required this.value,
    required this.units,
    required this.onChanged,
    required this.label,
  });

  final String value;
  final Map<String, Map<String, dynamic>> units;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: units.entries
              .map((e) => DropdownMenuItem<String>(
            value: e.key,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: (e.value['color'] as Color).withOpacity(.9),
                    shape: BoxShape.circle,
                  ),
                ),
                Text('${e.key} (${e.value['symbol']})'),
              ],
            ),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
