import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../../data/models/group_update_request.dart';
import '../bloc/group_management_bloc.dart';
import '../bloc/group_management_event.dart';
import '../bloc/group_management_state.dart';

class GroupEditScreen extends StatefulWidget {
  final Group group;

  const GroupEditScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description ?? '');

    // Listen for changes
    _nameController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != widget.group.name;
    final descriptionChanged = _descriptionController.text.trim() != (widget.group.description ?? '');

    setState(() {
      _hasChanges = nameChanged || descriptionChanged;
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

      final request = GroupUpdateRequest(
        name: _nameController.text.trim() != widget.group.name
            ? _nameController.text.trim()
            : null,
        description: _descriptionController.text.trim() != (widget.group.description ?? '')
            ? (_descriptionController.text.trim().isEmpty ? '' : _descriptionController.text.trim())
            : null,
      );

      context.read<GroupManagementBloc>().add(
            GroupManagementUpdateRequested(widget.group.id, request),
          );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
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
      child: BlocListener<GroupManagementBloc, GroupManagementState>(
        listener: (context, state) {
          if (state is GroupManagementOperationInProgress) {
            setState(() {
              _isSubmitting = true;
            });
          } else if (state is GroupManagementOperationSuccess) {
            setState(() {
              _isSubmitting = false;
            });
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Navigate back with success result
            Navigator.pop(context, true);
          } else if (state is GroupManagementError) {
            setState(() {
              _isSubmitting = false;
            });
            // Show error message
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
          appBar: AppBar(
            title: const Text('Edit Group'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card with icon
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 32,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Group',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update group information',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Group Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name *',
                    hintText: 'e.g., Engineering Team',
                    prefixIcon: const Icon(Icons.groups),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Group name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Group name must be at least 3 characters';
                    }
                    if (value.trim().length > 50) {
                      return 'Group name must be less than 50 characters';
                    }
                    return null;
                  },
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Describe the purpose of this group',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value != null && value.trim().length > 200) {
                      return 'Description must be less than 200 characters';
                    }
                    return null;
                  },
                  enabled: !_isSubmitting,
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
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
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
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Members and door access are managed separately',
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
                    onPressed: (_isSubmitting || !_hasChanges) ? null : _submitForm,
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
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
