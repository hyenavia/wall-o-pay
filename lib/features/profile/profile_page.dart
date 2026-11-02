import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n.dart';
import '../../core/widgets.dart';
import '../../data/cloud.dart';
import '../../data/profile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _nickname;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(
      text: ref.read(profileProvider).nickname ?? '',
    );
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await ref.read(profileProvider.notifier).setPhoto(bytes);
    } catch (e) {
      if (mounted) {
        _toast(context.tr('Could not pick a photo: {error}', {'error': e}));
      }
    }
  }

  Future<void> _save() async {
    await ref.read(profileProvider.notifier).setNickname(_nickname.text);
    if (mounted) _toast(context.tr('Profile saved.'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final username = ref.watch(usernameProvider);
    final hasPhoto = ref.watch(profileProvider.select((s) => s.photo != null));
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Profile'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: Stack(
              children: [
                const UserAvatar(size: 112),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 20,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _pickPhoto,
                child: Text(context.tr('Change photo')),
              ),
              if (hasPhoto)
                TextButton(
                  onPressed: () => ref.read(profileProvider.notifier).setPhoto(null),
                  child: Text(context.tr('Remove photo')),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nickname,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            decoration: appInput(
              context,
              label: context.tr('Nickname'),
              helper: context.tr('Shown in your greeting on the Home screen.'),
            ),
          ),
          const SizedBox(height: 8),
          if (username != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alternate_email),
              title: Text(username),
              subtitle: Text(context.tr('Username')),
            ),
          if (user?.email != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: Text(user!.email!),
              subtitle: Text(context.tr('Email')),
            ),
          Text(
            context.tr('Your username is used to log in and cannot be changed.'),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: Text(context.tr('Save'))),
        ],
      ),
    );
  }
}
