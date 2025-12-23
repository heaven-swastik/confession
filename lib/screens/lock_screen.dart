import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _enteredPin = '';
  String? _savedPin;
  bool _isSettingUp = false;
  String _setupPin = '';
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkPinSetup();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkPinSetup() async {
    final pin = await _secureStorage.read(key: 'app_pin');
    setState(() {
      _savedPin = pin;
      _isSettingUp = pin == null;
    });
  }

  void _onNumberTap(String number) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += number;
    });

    if (_enteredPin.length == 4) {
      if (_isSettingUp) {
        if (_setupPin.isEmpty) {
          _setupPin = _enteredPin;
          _enteredPin = '';
        } else {
          if (_enteredPin == _setupPin) {
            _savePin(_enteredPin);
          } else {
            _shakeAnimation();
            _showError("PINs don't match. Try again.");
            _enteredPin = '';
            _setupPin = '';
          }
        }
      } else {
        if (_enteredPin == _savedPin) {
          widget.onUnlocked();
        } else {
          _shakeAnimation();
          _showError("Incorrect PIN");
          _enteredPin = '';
        }
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  Future<void> _savePin(String pin) async {
    await _secureStorage.write(key: 'app_pin', value: pin);
    setState(() {
      _savedPin = pin;
      _isSettingUp = false;
      _enteredPin = '';
      _setupPin = '';
    });
    widget.onUnlocked();
  }

  void _shakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Icon(Icons.lock_outline, size: 72, color: AppTheme.accent),
                  const SizedBox(height: 24),
                  Text(
                    _isSettingUp
                        ? (_setupPin.isEmpty ? 'Create Your PIN' : 'Confirm Your PIN')
                        : 'Enter PIN',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSettingUp
                        ? 'Keep your confessions safe with a 4-digit PIN 🔒'
                        : 'Welcome back',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textColor.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final offset = _shakeController.value < 0.5
                          ? _shakeController.value * 20
                          : (1 - _shakeController.value) * 20;
                      return Transform.translate(offset: Offset(offset, 0), child: child);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < _enteredPin.length
                                ? AppTheme.accent
                                : AppTheme.accent.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildNumberPad(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildNumberRow(['1', '2', '3']),
        _buildNumberRow(['4', '5', '6']),
        _buildNumberRow(['7', '8', '9']),
        _buildNumberRow(['', '0', 'backspace']),
      ],
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: numbers.map((number) {
          if (number.isEmpty) return const SizedBox(width: 80, height: 80);
          if (number == 'backspace') {
            return _buildNumberButton(
              onTap: _onBackspace,
              child: const Icon(Icons.backspace_outlined, color: AppTheme.textColor),
            );
          }
          return _buildNumberButton(
            onTap: () => _onNumberTap(number),
            child: Text(number, style: Theme.of(context).textTheme.displaySmall),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNumberButton({required VoidCallback onTap, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Material(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(width: 80, height: 80, alignment: Alignment.center, child: child),
        ),
      ),
    );
  }
}
