/// Halaman pengaturan profil pengguna ([ProfilePage]) untuk mengganti foto profil dan nama panggilan (nickname).
library;

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/cloud.dart';
import '../../data/profile.dart';

/// Widget halaman Profil untuk mengelola avatar dan nama sapaan pengguna.
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ProfilePhotoCropPage(imageBytes: bytes),
        ),
      );
      if (cropped == null) return;
      await ref.read(profileProvider.notifier).setPhoto(cropped);
      if (mounted) _toast(context.tr('Profile photo updated.'));
    } catch (e) {
      if (mounted) {
        _toast(context.tr('Could not pick a photo: {error}', {'error': e}));
      }
    }
  }

  void _viewPhoto() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfilePhotoViewPage()));
  }

  Future<void> _confirmRemovePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(dialogCtx.tr('Remove photo?')),
        content: Text(
          dialogCtx.tr('Are you sure you want to remove your profile photo?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(dialogCtx.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(dialogCtx.tr('Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(profileProvider.notifier).setPhoto(null);
      if (mounted) _toast(context.tr('Profile photo removed.'));
    }
  }

  void _showPhotoBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ProfileCustomizeSheet(
        onPickCamera: () => _pickPhoto(ImageSource.camera),
        onPickGallery: () => _pickPhoto(ImageSource.gallery),
        onViewPhoto: _viewPhoto,
        onRemovePhoto: _confirmRemovePhoto,
        onApplied: (msg) {
          if (mounted) _toast(msg);
        },
      ),
    );
  }

  Future<void> _save() async {
    await ref.read(profileProvider.notifier).setNickname(_nickname.text);
    if (mounted) _toast(context.tr('Profile saved.'));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(profileProvider.select((s) => s.nickname), (prev, next) {
      final expectedPrev = prev ?? '';
      if (_nickname.text == expectedPrev && _nickname.text != (next ?? '')) {
        _nickname.text = next ?? '';
      }
    });

    final colors = context.themeColors;
    final user = ref.watch(currentUserProvider);
    final username = ref.watch(usernameProvider);

    return Scaffold(
      appBar: secondaryAppBar(context, title: Text(context.tr('Profile'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
                UserAvatar(
                  size: 104,
                  withGlassFrame: false,
                  heroTag: 'profile_photo_hero',
                  onTap: () => _showPhotoBottomSheet(context),
                ),
                const SizedBox(height: 36),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(
                      color: colors.accentSecondary.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  icon: Icon(
                    Icons.auto_fix_high_rounded,
                    size: 18,
                    color: colors.accentSecondary,
                  ),
                  onPressed: () => _showPhotoBottomSheet(context),
                  label: Text(context.tr('Customize Avatar & Frame')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nickname,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 30,
                  decoration: appInput(
                    context,
                    label: context.tr('Nickname'),
                    helper: context.tr(
                      'Shown in your greeting on the Home screen.',
                    ),
                  ),
                ),
                if (username != null) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.alternate_email,
                      color: colors.textMuted,
                    ),
                    title: Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      context.tr('Username'),
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                ],
                if (user?.email != null) ...[
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.mail_outline,
                      color: colors.textMuted,
                    ),
                    title: Text(
                      user!.email!,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      context.tr('Email'),
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    user == null
                        ? 'You are in Guest mode. Your profile is saved locally on this device.'
                        : 'Your username is used to log in and cannot be changed.',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.isDark
                        ? AppColors.glasshouseGreen
                        : colors.primary,
                    foregroundColor: colors.isDark
                        ? AppColors.softIvory
                        : colors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: colors.isDark
                            ? AppColors.dewMint.withValues(alpha: 0.35)
                            : colors.primary,
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: _save,
                  child: Text(
                    context.tr('Save'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Item aksi foto bergaya bundar seperti WhatsApp.
class _ProfileCustomizeSheet extends ConsumerStatefulWidget {
  const _ProfileCustomizeSheet({
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onViewPhoto,
    required this.onRemovePhoto,
    required this.onApplied,
  });

  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onViewPhoto;
  final VoidCallback onRemovePhoto;
  final void Function(String message) onApplied;

  @override
  ConsumerState<_ProfileCustomizeSheet> createState() =>
      _ProfileCustomizeSheetState();
}

class _ProfileCustomizeSheetState
    extends ConsumerState<_ProfileCustomizeSheet> {
  int _tab = 0; // 0 = Avatar, 1 = Profile Frame
  String? _pendingChibiAsset;
  late String? _pendingFrameId = ref.read(profileProvider).frameId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final selBorder = colors.isDark ? AppColors.goldenYellow : colors.primary;
    final profile = ref.watch(profileProvider);
    final hasPhoto = profile.photo != null;
    final currentFrameId = profile.frameId;
    final frameChanged = _pendingFrameId != currentFrameId;
    final avatarChanged = _pendingChibiAsset != null;
    final hasPendingChanges = avatarChanged || frameChanged;
    final maxH = MediaQuery.of(context).size.height * 0.78;

    final previewFrameAsset = profileFrameAssetPath(_pendingFrameId);
    final Widget previewAvatarCore = CircleAvatar(
      radius: 34,
      backgroundColor: colors.surfaceContainer,
      child: _pendingChibiAsset != null
          ? ClipOval(
              child: Image.asset(
                _pendingChibiAsset!,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
              ),
            )
          : (profile.photoImage != null
              ? ClipOval(
                  child: Image(
                    image: profile.photoImage!,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                  ),
                )
              : const UserAvatar(size: 68)),
    );

    final Widget previewWithFrame = previewFrameAsset == null
        ? previewAvatarCore
        : SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                previewAvatarCore,
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: profileFrameScale(_pendingFrameId),
                        child: FractionalTranslation(
                          translation: profileFrameOffset(_pendingFrameId),
                          child: Image.asset(
                            previewFrameAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: BoxDecoration(
            color: colors.isDark ? AppColors.midnightNavy : colors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: colors.borderOutline.withValues(alpha: 0.9),
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('Customize Avatar & Frame'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (hasPhoto)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: colors.expense,
                        ),
                        tooltip: context.tr('Remove photo'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onRemovePhoto();
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textPrimary,
                      ),
                      tooltip: context.tr('Close'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text(context.tr('Avatar')),
                      icon: const Icon(Icons.face_retouching_natural_rounded, size: 18),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text(context.tr('Profile Frame')),
                      icon: const Icon(Icons.filter_frames_rounded, size: 18),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _tab == 0
                    ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 92,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: 12,
                        itemBuilder: (ctx, index) {
                          if (index == 0) {
                            return _CustomizeActionTile(
                              icon: Icons.photo_camera_rounded,
                              label: context.tr('Camera'),
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onPickCamera();
                              },
                            );
                          }
                          if (index == 1) {
                            return _CustomizeActionTile(
                              icon: Icons.photo_library_rounded,
                              label: context.tr('Gallery'),
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onPickGallery();
                              },
                            );
                          }
                          final avatarNum =
                              (index - 1).toString().padLeft(2, '0');
                          final assetPath =
                              'assets/new_asset/profile_avatar/avatar_$avatarNum.png';
                          final isSelected = _pendingChibiAsset == assetPath;
                          return Semantics(
                            button: true,
                            selected: isSelected,
                            label: 'Avatar ${index - 1}',
                            child: ExcludeSemantics(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => setState(
                                  () => _pendingChibiAsset = assetPath,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primary.withValues(alpha: 0.14)
                                        : colors.cardSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? selBorder
                                          : colors.isDark
                                              ? AppColors.neonCyan
                                                  .withValues(alpha: 0.30)
                                              : colors.borderOutline,
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      assetPath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 120,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                        itemCount: profileFrameIds.length + 1,
                        itemBuilder: (ctx, i) {
                          final isNone = i == 0;
                          final id = isNone ? null : profileFrameIds[i - 1];
                          final isSelected = _pendingFrameId == id;
                          final label = isNone
                              ? context.tr('None')
                              : context.tr('Frame {n}', {'n': '$i'});
                          return Semantics(
                            button: true,
                            selected: isSelected,
                            label: label,
                            child: ExcludeSemantics(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () =>
                                    setState(() => _pendingFrameId = id),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primary.withValues(alpha: 0.14)
                                        : colors.cardSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? selBorder
                                          : colors.borderOutline,
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: isNone
                                            ? Icon(
                                                Icons.block_rounded,
                                                size: 32,
                                                color: isSelected
                                                    ? selBorder
                                                    : colors.textMuted,
                                              )
                                            : Image.asset(
                                                profileFrameAssetPath(id)!,
                                                fit: BoxFit.contain,
                                              ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? colors.textPrimary
                                              : colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  border: Border(
                    top: BorderSide(
                      color: colors.borderOutline.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    previewWithFrame,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _pendingFrameId == null
                                ? context.tr('None')
                                : context.tr('Frame {n}', {
                                    'n':
                                        '${profileFrameIds.indexOf(_pendingFrameId!) + 1}',
                                  }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasPendingChanges
                                ? context.tr('Ready to apply')
                                : context.tr('In Use'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasPendingChanges
                                  ? colors.accentSecondary
                                  : colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasPhoto && !hasPendingChanges) ...[
                      IconButton(
                        tooltip: context.tr('View Photo'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onViewPhoto();
                        },
                        icon: Icon(
                          Icons.visibility_outlined,
                          color: colors.accentSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    FilledButton(
                      onPressed: !hasPendingChanges || _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              try {
                                final notifier =
                                    ref.read(profileProvider.notifier);
                                if (_pendingChibiAsset != null) {
                                  final data =
                                      await rootBundle.load(_pendingChibiAsset!);
                                  await notifier
                                      .setPhoto(data.buffer.asUint8List());
                                }
                                if (frameChanged) {
                                  await notifier.setFrame(_pendingFrameId);
                                }
                                if (context.mounted) {
                                  final msg = context.tr(
                                    _pendingChibiAsset != null
                                        ? 'Wendy avatar selected!'
                                        : 'Profile frame updated.',
                                  );
                                  Navigator.of(context).pop();
                                  widget.onApplied(msg);
                                }
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      child: _saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Text(
                              hasPendingChanges
                                  ? context.tr('Apply')
                                  : context.tr('In Use'),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomizeActionTile extends StatelessWidget {
  const _CustomizeActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.surfaceContainer.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderOutline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: colors.accentSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoActionItem extends StatelessWidget {
  const _PhotoActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final accent = colors.isDark ? AppColors.dewMint : colors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Halaman sesi Crop / Potong Foto Profil bergaya WhatsApp.
/// Memungkinkan pengguna menggeser, memperbesar (zoom), dan memutar foto dalam lingkaran viewfinder.
class ProfilePhotoCropPage extends StatefulWidget {
  const ProfilePhotoCropPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<ProfilePhotoCropPage> createState() => _ProfilePhotoCropPageState();
}

class _ProfilePhotoCropPageState extends State<ProfilePhotoCropPage> {
  final TransformationController _transformController =
      TransformationController();
  ui.Image? _rawImage;
  bool _isLoading = true;
  bool _isSaving = false;
  int _quarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _rawImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _rotate() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
    });
  }

  void _reset() {
    setState(() {
      _quarterTurns = 0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _cropAndSave(double cropSize) async {
    if (_rawImage == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      const targetSize = 512.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, targetSize, targetSize),
      );

      final scaleFactor = targetSize / cropSize;
      canvas.scale(scaleFactor, scaleFactor);
      canvas.transform(_transformController.value.storage);

      final rawW = _rawImage!.width.toDouble();
      final rawH = _rawImage!.height.toDouble();
      final isRotated = _quarterTurns % 2 == 1;
      final effW = isRotated ? rawH : rawW;
      final effH = isRotated ? rawW : rawH;

      final fitScale = min(cropSize / effW, cropSize / effH);
      final drawW = effW * fitScale;
      final drawH = effH * fitScale;
      final dx = (cropSize - drawW) / 2;
      final dy = (cropSize - drawH) / 2;

      canvas.save();
      canvas.translate(dx + drawW / 2, dy + drawH / 2);
      canvas.rotate(_quarterTurns * pi / 2);
      canvas.translate(-rawW * fitScale / 2, -rawH * fitScale / 2);
      canvas.drawImageRect(
        _rawImage!,
        Rect.fromLTWH(0, 0, rawW, rawH),
        Rect.fromLTWH(0, 0, rawW * fitScale, rawH * fitScale),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();

      final picture = recorder.endRecording();
      final croppedImg = await picture.toImage(
        targetSize.toInt(),
        targetSize.toInt(),
      );
      final byteData = await croppedImg.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null && mounted) {
        Navigator.of(context).pop(byteData.buffer.asUint8List());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Could not pick a photo: {error}', {'error': e}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr('Crop Photo'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: context.tr('Reset'),
            onPressed: _reset,
          ),
          IconButton(
            icon: const Icon(
              Icons.rotate_90_degrees_cw_outlined,
              color: Colors.white,
            ),
            tooltip: context.tr('Rotate'),
            onPressed: _rotate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, constraints) {
                final maxDim = min(
                  constraints.maxWidth - 32,
                  constraints.maxHeight - 120,
                );
                final cropSize = maxDim.clamp(240.0, 360.0);

                final rawW = _rawImage!.width.toDouble();
                final rawH = _rawImage!.height.toDouble();
                final isRotated = _quarterTurns % 2 == 1;
                final effW = isRotated ? rawH : rawW;
                final effH = isRotated ? rawW : rawH;

                final fitScale = min(cropSize / effW, cropSize / effH);
                final drawW = effW * fitScale;
                final drawH = effH * fitScale;

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: cropSize,
                          height: cropSize,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRect(
                                child: InteractiveViewer(
                                  transformationController:
                                      _transformController,
                                  minScale: 0.8,
                                  maxScale: 4.0,
                                  boundaryMargin: EdgeInsets.all(
                                    cropSize * 0.8,
                                  ),
                                  child: SizedBox(
                                    width: cropSize,
                                    height: cropSize,
                                    child: Center(
                                      child: RotatedBox(
                                        quarterTurns: _quarterTurns,
                                        child: SizedBox(
                                          width: isRotated ? drawH : drawW,
                                          height: isRotated ? drawW : drawH,
                                          child: Image.memory(
                                            widget.imageBytes,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: CustomPaint(
                                  size: Size(cropSize, cropSize),
                                  painter: const _WhatsAppCropOverlayPainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        child: Row(
                          children: [
                            Flexible(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  context.tr('Cancel'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.rotate_90_degrees_cw_outlined,
                                color: Colors.white,
                              ),
                              tooltip: context.tr('Rotate'),
                              onPressed: _rotate,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _cropAndSave(cropSize),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check, size: 18),
                                label: Text(
                                  context.tr('Done'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Overlay masker pemotong lingkaran WhatsApp.
class _WhatsAppCropOverlayPainter extends CustomPainter {
  const _WhatsAppCropOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Lapisan gelap di luar lingkaran
    final overlayPath = Path()
      ..addRect(rect)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    // 2. Garis lingkaran putih
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 3. Garis pandu grid rule-of-thirds di dalam lingkaran
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final step = size.width / 3;
    canvas.drawLine(Offset(step, 0), Offset(step, size.height), gridPaint);
    canvas.drawLine(
      Offset(step * 2, 0),
      Offset(step * 2, size.height),
      gridPaint,
    );
    canvas.drawLine(Offset(0, step), Offset(size.width, step), gridPaint);
    canvas.drawLine(
      Offset(0, step * 2),
      Offset(size.width, step * 2),
      gridPaint,
    );
    canvas.restore();

    // 4. Bracket sudut bingkai foto (gaya WhatsApp)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    const cornerLen = 18.0;

    // Kiri-atas
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, 0)
        ..lineTo(cornerLen, 0),
      cornerPaint,
    );
    // Kanan-atas
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLen),
      cornerPaint,
    );
    // Kiri-bawah
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLen)
        ..lineTo(0, size.height)
        ..lineTo(cornerLen, size.height),
      cornerPaint,
    );
    // Kanan-bawah
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Halaman penampil foto profil layar penuh (gaya WhatsApp) dengan zoom & pan interaktif.
class ProfilePhotoViewPage extends ConsumerWidget {
  const ProfilePhotoViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final photo = profile.photo;
    final name = ref.watch(displayNameProvider) ?? context.tr('Profile Photo');

    // Jika foto dihapus saat di viewer, otomatis kembali.
    if (photo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: context.tr('Change photo'),
            onPressed: () => _showPicker(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            tooltip: context.tr('Remove photo'),
            onPressed: () => _confirmRemove(context, ref),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: Hero(
            tag: 'profile_photo_hero',
            child: Image.memory(photo, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(sheetCtx).colorScheme.onSurface
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sheetCtx.tr('Change photo'),
                      style: Theme.of(sheetCtx).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PhotoActionItem(
                    icon: Icons.photo_camera_rounded,
                    label: sheetCtx.tr('Camera'),
                    onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
                  ),
                  _PhotoActionItem(
                    icon: Icons.photo_library_rounded,
                    label: sheetCtx.tr('Gallery'),
                    onTap: () =>
                        Navigator.of(sheetCtx).pop(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (source != null && context.mounted) {
      try {
        final picked = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 90,
        );
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        if (!context.mounted) return;

        final cropped = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(
            builder: (_) => ProfilePhotoCropPage(imageBytes: bytes),
          ),
        );
        if (cropped == null) return;
        await ref.read(profileProvider.notifier).setPhoto(cropped);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('Profile photo updated.'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('Could not pick a photo: {error}', {'error': e}),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(dialogCtx.tr('Remove photo?')),
        content: Text(
          dialogCtx.tr('Are you sure you want to remove your profile photo?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(dialogCtx.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(dialogCtx.tr('Delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(profileProvider.notifier).setPhoto(null);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Profile photo removed.'))),
        );
      }
    }
  }
}
