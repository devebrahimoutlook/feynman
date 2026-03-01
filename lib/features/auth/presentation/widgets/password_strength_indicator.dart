import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final length = password.length;
    double strength = 0.0;
    Color color = Colors.red;

    if (length >= 8) {
      // Very basic strength calculation for MVP
      final hasUppercase = password.contains(RegExp(r'[A-Z]'));
      final hasDigits = password.contains(RegExp(r'[0-9]'));
      final hasSpecial = password.contains(RegExp(r'[!@#\$&*~]'));

      int score =
          1 +
          (hasUppercase ? 1 : 0) +
          (hasDigits ? 1 : 0) +
          (hasSpecial ? 1 : 0);

      if (score == 1) {
        strength = 0.33;
        color = Colors.orange;
      } else if (score == 2 || score == 3) {
        strength = 0.66;
        color = Colors.lightGreen;
      } else if (score >= 4) {
        strength = 1.0;
        color = Colors.green;
      }
    } else if (length > 0) {
      strength = 0.15;
    }

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: strength,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 6),
          Text(
            _getStrengthString(strength),
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getStrengthString(double strength) {
    if (strength <= 0.15) return 'Too short';
    if (strength <= 0.33) return 'Weak';
    if (strength <= 0.66) return 'Good';
    return 'Strong';
  }
}
