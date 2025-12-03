import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/ui/widgets/gravatar_avatar.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../../data/models/user_update_request.dart';
import '../bloc/user_management_bloc.dart';
import '../bloc/user_management_event.dart';
import '../bloc/user_management_state.dart';

class UserEditScreen extends StatefulWidget {
  final User user;

  const UserEditScreen({super.key, required this.user});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _fullNameController;
  late String _selectedRole;
  bool _isSubmitting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _selectedRole = widget.user.role;

    // Listen for changes
    _emailController.addListener(_checkForChanges);
    _fullNameController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final emailChanged = _emailController.text.trim() != widget.user.email;
    final nameChanged = _fullNameController.text.trim() != widget.user.fullName;
    final roleChanged = _selectedRole != widget.user.role;

    setState(() {
      _hasChanges = emailChanged || nameChanged || roleChanged;
    });
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final request = UserUpdateRequest(
        email: _emailController.text.trim() != widget.user.email
            ? _emailController.text.trim()
            : null,
        fullName: _fullNameController.text.trim() != widget.user.fullName
            ? _fullNameController.text.trim()
            : null,
        role: _selectedRole != widget.user.role ? _selectedRole : null,
      );

      context.read<UserManagementBloc>().add(
        UserManagementUpdateRequested(widget.user.id, request),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: BlocListener<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          if (state is UserManagementOperationInProgress) {
            setState(() {
              _isSubmitting = true;
            });
          } else if (state is UserManagementOperationSuccess) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is UserManagementError) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Edit User')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GravatarAvatar(
                          email: widget.user.email,
                          radius: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit User',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update user account information',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'user@example.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,5}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),

                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'John Doe',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Full name must be at least 3 characters';
                    }
                    return null;
                  },
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),

                // Role Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Role *',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        RadioGroup<String>(
                          groupValue: _selectedRole,
                          onChanged: _isSubmitting
                              ? (value) {}
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedRole = value;
                                      _checkForChanges();
                                    });
                                  }
                                },
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text('User'),
                                subtitle: const Text(
                                  'Regular user with standard permissions',
                                ),
                                value: 'user',
                              ),
                              RadioListTile<String>(
                                title: const Text('Admin'),
                                subtitle: const Text(
                                  'Administrator with full access',
                                ),
                                value: 'admin',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info display
                if (_hasChanges)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You have unsaved changes',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Note: Password cannot be changed here. User must change their own password.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || !_hasChanges)
                        ? null
                        : _submitForm,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (_hasChanges) {
                              final shouldPop = await _onWillPop();
                              if (shouldPop && context.mounted) {
                                Navigator.pop(context);
                              }
                            } else {
                              Navigator.pop(context);
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
