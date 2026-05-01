import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/user/models/user_model.dart';
import 'package:purewill/features/user/providers/profile_provider.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullnameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  bool _submitting = false;
  File? _avatarFile;
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _fullnameController = TextEditingController(
      text: widget.user.fullName ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.user.username ?? '',
    );
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final success = await ref
        .read(profileViewModelProvider.notifier)
        .updateProfile(
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          fullName: _fullnameController.text.trim(),
          gender: _selectedGender,
          birthDate: _selectedBirthDate,
          avatar: _avatarFile,
        );
    setState(() => _submitting = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    final state = ref.read(profileViewModelProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.errorMessage ?? 'Failed to update profile')),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);

      // Validate file size (max 5MB)
      const maxBytes = 5 * 1024 * 1024;
      final fileSize = await file.length();
      if (fileSize > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image too large. Max 5MB allowed.')),
        );
        return;
      }

      // Validate extension
      final allowedExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      final ext = picked.path.split('.').last.toLowerCase();
      if (!allowedExt.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported image type.')),
        );
        return;
      }

      setState(() => _avatarFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _pickBirthDate() async {
    final now = nowInIndonesia();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: state.isLoading && state.user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: _avatarFile != null
                                ? FileImage(_avatarFile!) as ImageProvider
                                : (widget.user.avatarUrl != null &&
                                      widget.user.avatarUrl!.isNotEmpty)
                                ? NetworkImage(widget.user.avatarUrl!)
                                : null,
                            child:
                                (_avatarFile == null &&
                                    (widget.user.avatarUrl == null ||
                                        widget.user.avatarUrl!.isEmpty))
                                ? const Icon(Icons.person, size: 48)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _pickAvatar,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fullnameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Minimum 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Minimum 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Email is required';
                        if (!text.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender (optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MALE', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'FEMALE',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Birth Date (optional)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedBirthDate == null
                              ? 'Select date'
                              : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting || state.isLoading
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _submitting || state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
