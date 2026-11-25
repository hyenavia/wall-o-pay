/// Halaman pengaturan keamanan ([SecurityPage]) untuk mengaktifkan kunci PIN 6 digit,
/// autentikasi biometrik (Fingerprint / Face Unlock), mengatur batas waktu kunci otomatis,
/// mengganti PIN, dan mengaktifkan Privacy Shield.
library;

import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/lock.dart';
import 'lock_screen.dart';

/// Widget halaman Pengaturan Keamanan aplikasi.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Lock.instance.refreshBiometricSupport();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !Lock.instance.isAuthenticatingBiometric) {
      Lock.instance.refreshBiometricSupport();
    }
  }

  Future<void> _toggle(BuildContext context, bool on) async {
    if (on) {
      final pin = await createPin(context);
      if (pin != null) {
        await Lock.instance.setPin(pin);
        await Lock.instance.refreshBiometricSupport();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('PIN lock enabled.'))),
          );
        }
      }
    } else {
      final ok = await askPin(context, title: context.tr('Enter PIN to disable'));
      if (ok) {
        await Lock.instance.disable();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('PIN lock disabled.'))),
          );
        }
      }
    }
  }

  Future<void> _toggleBiometric(BuildContext context, bool on) async {
    final ok = await Lock.instance.setBiometric(
      on,
      localizedReason: context.tr('Verify your identity to enable Biometric Unlock'),
    );
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(on ? 'Biometric unlock enabled.' : 'Biometric unlock disabled.'),
          ),
        ),
      );
    } else if (on) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Biometric verification failed or canceled.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final secAccent = colors.isDark ? AppColors.dewMint : colors.primary;
    return Scaffold(
      appBar: secondaryAppBar(context, title: Text(context.tr('Security'))),
      body: ValueListenableBuilder<AppLockState>(
        valueListenable: Lock.instance.state,
        builder: (context, st, _) {
          final bioTitle = st.isFaceOnly
              ? context.tr('Face Unlock')
              : st.isFingerprintOnly
                  ? context.tr('Fingerprint Unlock')
                  : context.tr('Biometric Unlock');

          final bioSubtitle = !st.biometricAvailable
              ? context.tr('No fingerprint or face biometrics enrolled on this device.')
              : st.isFaceOnly
                  ? context.tr('Unlock the app quickly using Face Unlock alongside your PIN.')
                  : st.isFingerprintOnly
                      ? context.tr('Unlock the app quickly using your fingerprint alongside your PIN.')
                      : context.tr('Unlock the app quickly using fingerprint or face recognition alongside your PIN.');

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: st.enabled
                              ? secAccent.withValues(alpha: 0.16)
                              : colors.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: AppDuotoneIcon(
                          PhosphorIconsDuotone.lockKey,
                          size: 20,
                          color: st.enabled ? secAccent : colors.textMuted,
                        ),
                      ),
                      title: Text(
                        context.tr('App PIN Lock'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        context.tr('PIN protects your financial data and automatically syncs across your devices.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                      value: st.enabled,
                      onChanged: (v) => _toggle(context, v),
                    ),
                    if (st.enabled) ...[
                      Divider(
                        height: 28,
                        color: colors.borderOutline.withValues(alpha: 0.45),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: st.biometricEnabled
                                ? secAccent.withValues(alpha: 0.16)
                                : colors.surfaceContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: st.biometricEnabled
                                  ? secAccent.withValues(alpha: 0.35)
                                  : colors.borderOutline,
                              width: 0.8,
                            ),
                          ),
                          child: AppDuotoneIcon(
                            PhosphorIconsDuotone.fingerprint,
                            size: 20,
                            color: st.biometricEnabled ? secAccent : colors.textMuted,
                          ),
                        ),
                        title: Text(
                          bioTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          bioSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                        value: st.biometricEnabled,
                        onChanged: st.biometricAvailable
                            ? (v) => _toggleBiometric(context, v)
                            : null,
                      ),
                      Divider(
                        height: 28,
                        color: colors.borderOutline.withValues(alpha: 0.45),
                      ),
                      Text(
                        context.tr('Auto-lock timeout'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: secAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('Require PIN after leaving the app for:'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<int>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: 0, label: Text(context.tr('Immediately'))),
                            ButtonSegment(value: 1, label: Text(context.tr('1 minute'))),
                            ButtonSegment(value: 5, label: Text(context.tr('5 minutes'))),
                          ],
                          selected: {st.delayMin},
                          onSelectionChanged: (s) => Lock.instance.setDelay(s.first),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secAccent,
                          side: BorderSide(
                            color: secAccent.withValues(alpha: 0.45),
                          ),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (!await askPin(context, title: context.tr('Enter old PIN')) || !context.mounted) return;
                          final pin = await createPin(context);
                          if (pin != null) {
                            await Lock.instance.setPin(pin);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.tr('PIN successfully updated.'))),
                              );
                            }
                          }
                        },
                        icon: AppDuotoneIcon(
                          PhosphorIconsDuotone.key,
                          size: 20,
                          color: secAccent,
                        ),
                        label: Text(context.tr('Change PIN')),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.tr('Privacy Shield'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('Hide app preview in Recent Apps switcher and block screenshots.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                  value: st.privacyShield,
                  onChanged: (v) => Lock.instance.setPrivacyShield(v),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

