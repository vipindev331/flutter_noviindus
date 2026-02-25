import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_utils.dart';
import '../../core/utils/navigation_utils.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  static const _bgColor = Color(0xFF111111);
  static const _surfaceColor = Color(0xFF1C1C1C);
  static const _borderColor = Color(0xFF2E2E2E);
  static const _hintColor = Color(0xFF6B6B6B);
  static const _subtitleColor = Color(0xFF8A8A8A);
  static const _redColor = Color(0xFFD93025);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onContinuePressed() async {
    AppUtils.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(phone: _phoneController.text.trim());

    if (!mounted) return;

    if (success) {
      NavigationUtils.pushAndRemoveUntil(context, const HomeScreen());
    } else {
      AppUtils.showSnackBar(context, auth.errorMessage, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildSubtitle(),
                const SizedBox(height: 40),
                _buildPhoneRow(),
                const Spacer(),
                _buildContinueButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Enter Your\nMobile Number',
      style: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.2,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Lorem ipsum dolor sit amet consectetur. Porta at id hac vitae. Et tortor at vehicula euismod mi viverra.',
      style: TextStyle(
        fontSize: 13,
        color: _subtitleColor,
        height: 1.55,
      ),
    );
  }

  Widget _buildPhoneRow() {
    return Row(
      children: [
        // Country code box
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+91',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Phone number input
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Enter Mobile Number',
              hintStyle: const TextStyle(
                color: _hintColor,
                fontSize: 14,
              ),
              filled: true,
              fillColor: _surfaceColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white38, width: 1.2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _redColor),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _redColor, width: 1.2),
              ),
              errorStyle: const TextStyle(color: _redColor, fontSize: 11),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              if (value.trim().length != 10) {
                return 'Enter a valid 10-digit number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Center(
          child: GestureDetector(
            onTap: auth.isLoading ? null : _onContinuePressed,
            child: Container(
              height: 60,
              padding: const EdgeInsets.only(left: 28, right: 6),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: _borderColor, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _redColor,
                      shape: BoxShape.circle,
                    ),
                    child: auth.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
