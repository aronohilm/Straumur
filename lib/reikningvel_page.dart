import 'package:flutter/material.dart';

class ReikningvelPage extends StatefulWidget {
  const ReikningvelPage({super.key});

  @override
  State<ReikningvelPage> createState() => _ReikningvelPageState();
}

class _ReikningvelPageState extends State<ReikningvelPage> {
  String _display = "0";
  String _currentValue = "0";
  String _operation = "";
  double _firstOperand = 0;
  bool _newOperation = true;

  void _onDigitPressed(String digit) {
    setState(() {
      if (_newOperation || _currentValue == "0") {
        _currentValue = digit;
        _newOperation = false;
      } else {
        _currentValue += digit;
      }
      _display = _currentValue;
    });
  }

  void _onOperationPressed(String operation) {
    setState(() {
      if (_operation.isNotEmpty && !_newOperation) {
        _calculateResult();
      }
      _firstOperand = double.tryParse(_currentValue) ?? 0;
      _operation = operation;
      _newOperation = true;
    });
  }

  void _onEqualsPressed() {
    setState(() {
      _calculateResult();
      _operation = "";
      _newOperation = true;
    });
  }

  void _calculateResult() {
    double secondOperand = double.tryParse(_currentValue) ?? 0;
    double result = 0;

    switch (_operation) {
      case "+":
        result = _firstOperand + secondOperand;
        break;
      case "-":
        result = _firstOperand - secondOperand;
        break;
      case "×":
        result = _firstOperand * secondOperand;
        break;
      case "÷":
        result = secondOperand != 0 ? _firstOperand / secondOperand : 0;
        break;
      default:
        return;
    }

    _currentValue = result.toString();
    if (_currentValue.endsWith(".0")) {
      _currentValue = _currentValue.substring(0, _currentValue.length - 2);
    }
    _display = _currentValue;
    _firstOperand = result;
  }

  void _onClearPressed() {
    setState(() {
      _display = "0";
      _currentValue = "0";
      _operation = "";
      _firstOperand = 0;
      _newOperation = true;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_currentValue.length > 1) {
        _currentValue = _currentValue.substring(0, _currentValue.length - 1);
      } else {
        _currentValue = "0";
      }
      _display = _currentValue;
    });
  }

  Widget _buildNumButton(String text, {VoidCallback? onPressed}) {
    Color buttonColor = const Color(0xFF002244);
    Color textColor = Colors.white;

    // Make the backspace button yellow (like on main page)
    if (text == "<") {
      textColor = Colors.amber;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            elevation: 0,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 25),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpButton(String text, {VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF002244),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(64, 64),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002B5B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 36),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Reiknivél",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
              ),
              child: Text(
                "ISK $_display",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number pad
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildNumButton("1", onPressed: () => _onDigitPressed("1")),
                            _buildNumButton("2", onPressed: () => _onDigitPressed("2")),
                            _buildNumButton("3", onPressed: () => _onDigitPressed("3")),
                            _buildOpButton("×", onPressed: () => _onOperationPressed("×")),
                          ],
                        ),
                        Row(
                          children: [
                            _buildNumButton("4", onPressed: () => _onDigitPressed("4")),
                            _buildNumButton("5", onPressed: () => _onDigitPressed("5")),
                            _buildNumButton("6", onPressed: () => _onDigitPressed("6")),
                            _buildOpButton("÷", onPressed: () => _onOperationPressed("÷")),
                          ],
                        ),
                        Row(
                          children: [
                            _buildNumButton("7", onPressed: () => _onDigitPressed("7")),
                            _buildNumButton("8", onPressed: () => _onDigitPressed("8")),
                            _buildNumButton("9", onPressed: () => _onDigitPressed("9")),
                            _buildOpButton("-", onPressed: () => _onOperationPressed("-")),
                          ],
                        ),
                        Row(
                          children: [
                            _buildNumButton("=", onPressed: _onEqualsPressed),
                            _buildNumButton("0", onPressed: () => _onDigitPressed("0")),
                            _buildNumButton("<", onPressed: _onBackspacePressed),
                            _buildOpButton("+", onPressed: () => _onOperationPressed("+")),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Operations
                  /*Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOpButton("×", onPressed: () => _onOperationPressed("×")),
                      _buildOpButton("÷", onPressed: () => _onOperationPressed("÷")),
                      _buildOpButton("-", onPressed: () => _onOperationPressed("-")),
                      _buildOpButton("+", onPressed: () => _onOperationPressed("+")),
                    ],
                  ),*/
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF002244),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // TODO: Connect this to your payment logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Senda í posa!'),
                      backgroundColor: Color(0xFF002244),
                    ),
                  );
                },
                child: const Text(
                  "SENDA Í POSA",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}