import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/auth/models/auth_model.dart';
import 'package:purewill/features/auth/providers/auth_provider.dart';
import 'package:purewill/features/auth/views/login_screen.dart';
import 'package:purewill/features/auth/view_models/auth_view_model.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';
import 'package:purewill/core/widgets/primary_action_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'MALE';
  DateTime? _selectedBirthDate = DateTime(1998, 1, 15);

  final TextEditingController _fullNameController = TextEditingController(
    text: 'Rahaditya Putra',
  );
  final TextEditingController _usernameController = TextEditingController(
    text: 'rahaditya.putra',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'rahaditya.putra@example.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'Password123!',
  );
  final TextEditingController _confirmPasswordController =
      TextEditingController(text: 'Password123!');
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: nowInIndonesia().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: nowInIndonesia(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _signUp() async {
    final authState = ref.watch(authNotifierProvider);
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _showSnackBar("Password and confirmation do not match!", isError: true);
      return;
    }
    if (_selectedBirthDate == null) {
      _showSnackBar("Please select your birth date!", isError: true);
      return;
    }

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signup(
            fullname: _fullNameController.text.trim(),
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            passwordConfirmation: _confirmPasswordController.text.trim(),
            gender: _selectedGender,
            birthDate: _selectedBirthDate!,
          );

      if (!mounted) return;

      _showSnackBar("Registration Successful! Please login.");

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } on AuthException catch (e) {
      _showSnackBar(
        "Registration Failed:\n${e.formattedMessage}",
        isError: true,
      );
    } catch (e) {
      _showSnackBar(
        "Registration Failed: ${authState.errorMessage ?? 'Unknown error'}",
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/auth/bg2.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                children: [
                  SizedBox(
                    height: screenHeight * 0.20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: screenWidth * 0.20,
                          height: screenWidth * 0.20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: const Color.fromRGBO(102, 121, 163, 1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                "assets/images/auth/icon.png",
                                width: screenWidth * 0.19,
                                height: screenWidth * 0.19,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          "Create New Account",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Welcome Back Continue Your Journey",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _fullNameController,
                                hintText: "Full Name",
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return ' ';
                                  }
                                  if (value.length < 3) {
                                    return ' ';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _usernameController,
                                hintText: "Username",
                                icon: Icons.alternate_email,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return ' ';
                                  }
                                  if (value.length < 3) {
                                    return ' ';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _emailController,
                                hintText: "Email Address",
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return ' ';
                                  }
                                  if (!value.contains('@')) {
                                    return ' ';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),
                              Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Gender:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedGender,
                                          isExpanded: true,
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                          ),
                                          iconSize: 24,
                                          elevation: 16,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                          ),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              _selectedGender = newValue!;
                                            });
                                          },
                                          items: <String>['MALE', 'FEMALE']
                                              .map<DropdownMenuItem<String>>((
                                                String value,
                                              ) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              })
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _selectBirthDate,
                                child: Container(
                                  height: 45,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cake,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedBirthDate == null
                                            ? "Birth Date"
                                            : "${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}",
                                        style: TextStyle(
                                          color: _selectedBirthDate == null
                                              ? Colors.grey
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _passwordController,
                                hintText: "Password",
                                icon: Icons.lock,
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return ' ';
                                  }
                                  if (value.length < 6) {
                                    return ' ';
                                  }
                                  return null;
                                },
                                onToggleObscure: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),

                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                hintText: "Confirm Password",
                                icon: Icons.lock_outline,
                                obscureText: _obscureConfirmPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return ' ';
                                  }
                                  return null;
                                },
                                onToggleObscure: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: PrimaryActionButton(
                                  text: "Register",
                                  onPressed: isLoading ? null : _signUp,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                    ),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Color.fromRGBO(82, 140, 207, 1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                errorStyle: const TextStyle(fontSize: 0, height: 0),
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              validator: validator,
            ),
          ),
          if (onToggleObscure != null)
            GestureDetector(
              onTap: onToggleObscure,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ),
          if (onToggleObscure == null) const SizedBox(width: 12),
        ],
      ),
    );
  }
}
