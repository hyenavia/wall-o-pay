import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/widgets.dart';
import '../../data/lock.dart';
import 'lock_screen.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  Future<void> _toggle(BuildContext context, bool on) async {
    if (on) {
      final pin = await createPin(context);
      if (pin != null) {
        await Lock.instance.setPin(pin);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Security'))),
      body: ValueListenableBuilder<AppLockState>(
        valueListenable: Lock.instance.state,
        builder: (context, st, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.tr('App PIN Lock'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        context.tr('PIN protects your financial data and automatically syncs across your devices.'),
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                      value: st.enabled,
                      onChanged: (v) => _toggle(context, v),
                    ),
                    if (st.enabled) ...[
                      const Divider(height: 28),
                      Text(
                        context.tr('Auto-lock timeout'),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('Require PIN after leaving the app for:'),
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
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
            ],
          );
        },
      ),
    );
  }
}

