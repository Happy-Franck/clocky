import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FlipClockApp());
}

class FlipClockApp extends StatelessWidget {
  const FlipClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flip Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const FlipClockScreen(),
    );
  }
}

class FlipClockScreen extends StatefulWidget {
  const FlipClockScreen({super.key});

  @override
  State<FlipClockScreen> createState() => _FlipClockScreenState();
}

class _FlipClockScreenState extends State<FlipClockScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  String? _backgroundImagePath;
  Color _digitColor = Colors.white;
  String _fontFamily = 'Default';
  bool _showSettings = false;

  final List<String> _availableFonts = [
    'Default',
    'Roboto',
    'Courier New',
    'Times New Roman',
    'Arial',
    'Georgia',
    'Verdana',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backgroundImagePath = prefs.getString('backgroundImage');
      _digitColor = Color(prefs.getInt('digitColor') ?? Colors.white.value);
      _fontFamily = prefs.getString('fontFamily') ?? 'Default';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_backgroundImagePath != null) {
      await prefs.setString('backgroundImage', _backgroundImagePath!);
    }
    await prefs.setInt('digitColor', _digitColor.value);
    await prefs.setString('fontFamily', _fontFamily);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _backgroundImagePath = image.path;
      });
      _savePreferences();
    }
  }

  Future<void> _pickColor() async {
    Color selectedColor = _digitColor;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: selectedColor,
            onColorChanged: (color) {
              selectedColor = color;
            },
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.accent: false,
            },
            heading: const Text('Sélectionner une couleur'),
            subheading: const Text('Nuance'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _digitColor = selectedColor;
              });
              _savePreferences();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectFont() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la police'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableFonts.length,
            itemBuilder: (context, index) {
              final font = _availableFonts[index];
              return ListTile(
                title: Text(
                  font,
                  style: TextStyle(
                    fontFamily: font == 'Default' ? null : font,
                  ),
                ),
                trailing: _fontFamily == font
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _fontFamily = font;
                  });
                  _savePreferences();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    final second = _currentTime.second.toString().padLeft(2, '0');
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      body: GestureDetector(
        onLongPress: () {
          setState(() {
            _showSettings = !_showSettings;
          });
        },
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                image: _backgroundImagePath != null
                    ? DecorationImage(
                        image: FileImage(File(_backgroundImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: _backgroundImagePath == null
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.grey.shade900, Colors.black],
                      )
                    : null,
              ),
            ),
            // Clock
            Center(
              child: orientation == Orientation.portrait
                  ? _buildPortraitClock(hour, minute, second)
                  : _buildLandscapeClock(hour, minute, second),
            ),
            // Settings button
            if (_showSettings)
              Positioned(
                top: 40,
                right: 20,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'image',
                      mini: true,
                      onPressed: _pickImage,
                      child: const Icon(Icons.image),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'color',
                      mini: true,
                      onPressed: _pickColor,
                      child: const Icon(Icons.color_lens),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'font',
                      mini: true,
                      onPressed: _selectFont,
                      child: const Icon(Icons.font_download),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'close',
                      mini: true,
                      backgroundColor: Colors.red,
                      onPressed: () {
                        setState(() {
                          _showSettings = false;
                        });
                      },
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitClock(String hour, String minute, String second) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Heures (ÉNORME)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlipDigit(
              digit: hour[0],
              color: _digitColor,
              fontFamily: _fontFamily,
              width: 180,
              height: 260,
              fontSize: 180,
            ),
            const SizedBox(width: 20),
            FlipDigit(
              digit: hour[1],
              color: _digitColor,
              fontFamily: _fontFamily,
              width: 180,
              height: 260,
              fontSize: 180,
            ),
          ],
        ),
        const SizedBox(height: 50),
        // Minutes et secondes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlipDigit(
              digit: minute[0],
              color: _digitColor,
              fontFamily: _fontFamily,
              width: 140,
              height: 200,
              fontSize: 140,
            ),
            const SizedBox(width: 15),
            FlipDigit(
              digit: minute[1],
              color: _digitColor,
              fontFamily: _fontFamily,
              width: 140,
              height: 200,
              fontSize: 140,
            ),
            const SizedBox(width: 30),
            // Secondes (grand)
            FlipDigit(
              digit: second[0],
              color: _digitColor,
              fontFamily: _fontFamily,
              width: 80,
              height: 120,
              fontSize: 80,
            ),
            const SizedBox(width: 10),
            FlipDigit(
              digit: second[1],
              color: _digitColor,
              fontFamily: _fontFamily,
              width: 80,
              height: 120,
              fontSize: 80,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandscapeClock(String hour, String minute, String second) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Heures
        FlipDigit(
          digit: hour[0],
          color: _digitColor,
          fontFamily: _fontFamily,
          width: 140,
          height: 200,
          fontSize: 140,
        ),
        const SizedBox(width: 15),
        FlipDigit(
          digit: hour[1],
          color: _digitColor,
          fontFamily: _fontFamily,
          width: 140,
          height: 200,
          fontSize: 140,
        ),
        const SizedBox(width: 30),
        const TimeSeparator(),
        const SizedBox(width: 30),
        // Minutes
        FlipDigit(
          digit: minute[0],
          color: _digitColor,
          fontFamily: _fontFamily,
          width: 140,
          height: 200,
          fontSize: 140,
        ),
        const SizedBox(width: 15),
        FlipDigit(
          digit: minute[1],
          color: _digitColor,
          fontFamily: _fontFamily,
          width: 140,
          height: 200,
          fontSize: 140,
        ),
        const SizedBox(width: 30),
        // Secondes (grand)
        FlipDigit(
          digit: second[0],
          color: _digitColor,
          fontFamily: _fontFamily,
          width: 80,
          height: 120,
          fontSize: 80,
        ),
        const SizedBox(width: 10),
        FlipDigit(
          digit: second[1],
          color: _digitColor,
          fontFamily: _fontFamily,
          width: 80,
          height: 120,
          fontSize: 80,
        ),
      ],
    );
  }
}

class FlipDigit extends StatefulWidget {
  final String digit;
  final Color color;
  final String fontFamily;
  final double width;
  final double height;
  final double fontSize;

  const FlipDigit({
    super.key,
    required this.digit,
    this.color = Colors.white,
    this.fontFamily = 'Default',
    this.width = 80,
    this.height = 120,
    this.fontSize = 72,
  });

  @override
  State<FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<FlipDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _previousDigit = '0';
  String _currentDigit = '0';

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _previousDigit = oldWidget.digit;
      _currentDigit = widget.digit;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * 3.14159;
        final isFirstHalf = _animation.value < 0.5;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildCard(_currentDigit, false),
                ),
                if (_animation.value > 0 && _animation.value < 1)
                  Positioned.fill(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(angle),
                      child: _buildCard(
                        isFirstHalf ? _previousDigit : _currentDigit,
                        isFirstHalf,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(String digit, bool isTop) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade800.withOpacity(0.9),
            Colors.grey.shade900.withOpacity(0.9),
          ],
        ),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Text(
          digit,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w900,
            color: widget.color,
            fontFamily: widget.fontFamily == 'Default' ? null : widget.fontFamily,
            letterSpacing: -2,
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(3, 3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeSeparator extends StatelessWidget {
  const TimeSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
