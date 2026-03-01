import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:feynman/core/router/route_names.dart';
import 'package:feynman/core/providers/auth_provider.dart';
import 'package:feynman/features/auth/presentation/controllers/profile_controller.dart';
import 'package:feynman/features/auth/presentation/widgets/avatar_picker.dart';
import 'package:feynman/features/auth/domain/usecases/sign_out_provider.dart';
import 'package:feynman/features/auth/domain/usecases/delete_account_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profile = ref
        .read(authStateProvider)
        .value
        ?.mapOrNull(authenticated: (s) => s.user);
    _nameController = TextEditingController(text: profile?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      ref.read(profileControllerProvider.notifier).updateDisplayName(name);
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.mapOrNull(authenticated: (s) => s.user);
    final profileState = ref.watch(profileControllerProvider);
    final isLoading = profileState.isLoading;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: AvatarPicker(
                currentAvatarUrl: user.avatarUrl,
                isLoading: isLoading,
                onImageCropped: (file) {
                  ref
                      .read(profileControllerProvider.notifier)
                      .uploadAvatar(file);
                },
              ),
            ),
            const SizedBox(height: 32),
            if (profileState.hasError) ...[
              Text(
                profileState.error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            ListTile(
              title: const Text('Email'),
              subtitle: Text(user.email),
              leading: const Icon(Icons.email),
            ),
            const Divider(),
            ListTile(
              title: const Text('Display Name'),
              leading: const Icon(Icons.person),
              subtitle: _isEditing
                  ? TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your name',
                      ),
                      enabled: !isLoading,
                      autofocus: true,
                    )
                  : Text(user.displayName ?? 'No name set'),
              trailing: _isEditing
                  ? IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: isLoading ? null : _saveProfile,
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          _nameController.text = user.displayName ?? '';
                        });
                      },
                    ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Account Type'),
              subtitle: Text(user.authProvider.toUpperCase()),
              leading: const Icon(Icons.security),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Log Out'),
              leading: const Icon(Icons.logout),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await ref.read(signOutProvider).call();
                  if (context.mounted) {
                    context.goNamed(RouteNames.login);
                  }
                }
              },
            ),
            ListTile(
              title: const Text('Delete Account'),
              leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteAccountDialog(BuildContext context) {
    final deleteController = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is IRREVERSIBLE. All your data will be permanently deleted.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('To confirm, type "DELETE" below:'),
            const SizedBox(height: 8),
            TextField(
              controller: deleteController,
              decoration: const InputDecoration(
                hintText: 'Type DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (deleteController.text == 'DELETE') {
                Navigator.pop(context);
                try {
                  await ref.read(deleteAccountProvider).call();
                  if (context.mounted) {
                    context.goNamed(RouteNames.login);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type "DELETE" to confirm'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}
