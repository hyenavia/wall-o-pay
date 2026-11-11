/// Halaman pengaturan keamanan ([SecurityPage]) untuk mengaktifkan kunci PIN 6 digit,
/// autentikasi biometrik (Fingerprint / Face Unlock), mengatur batas waktu kunci otomatis,
/// mengganti PIN, dan mengaktifkan Privacy Shield.
library;

import 'package:flutter/material.dart';

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
                      title: Text(
                        context.tr('App PIN Lock'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.softIvory,
                        ),
                      ),
                      subtitle: Text(
                        context.tr('PIN protects your financial data and automatically syncs across your devices.'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.freshSage,
                        ),
                      ),
                      value: st.enabled,
                      onChanged: (v) => _toggle(context, v),
                    ),
                    if (st.enabled) ...[
                      Divider(height: 28, color: AppColors.dewMint.withValues(alpha: 0.12)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: st.biometricEnabled
                                ? AppColors.dewMint.withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: st.biometricEnabled
                                  ? AppColors.dewMint.withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            st.isFaceOnly ? Icons.face_rounded : Icons.fingerprint_rounded,
                            color: st.biometricEnabled
                                ? AppColors.dewMint
                                : AppColors.freshSage,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          bioTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.softIvory,
                          ),
                        ),
                        subtitle: Text(
                          bioSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.freshSage,
                          ),
                        ),
                        value: st.biometricEnabled,
                        onChanged: st.biometricAvailable
                            ? (v) => _toggleBiometric(context, v)
                            : null,
                      ),
                      Divider(height: 28, color: AppColors.dewMint.withValues(alpha: 0.12)),
                      Text(
                        context.tr('Auto-lock timeout'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.dewMint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('Require PIN after leaving the app for:'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.freshSage,
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
                          foregroundColor: AppColors.dewMint,
                          side: BorderSide(
                            color: AppColors.dewMint.withValues(alpha: 0.4),
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
                        icon: const Icon(Icons.password_rounded, size: 20),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.softIvory,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('Hide app preview in Recent Apps switcher and block screenshots.'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.freshSage,
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

