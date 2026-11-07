import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/data/cloud.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/features/profile/profile_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1x1 transparent PNG bytes for testing image display
  final transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  Widget createTestWidget({
    required SharedPreferences prefs,
    Uint8List? initialPhoto,
    String? initialNickname,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(false),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('id'),
        ],
        home: const ProfilePage(),
      ),
    );
  }

  group('Profile Photo WhatsApp-style Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Tapping camera badge opens photo bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget(prefs: prefs));
      await tester.pumpAndSettle();

      // Camera badge icon button is present
      final cameraBadge = find.byIcon(Icons.photo_camera_outlined);
      expect(cameraBadge, findsWidgets);

      await tester.tap(cameraBadge.first);
      await tester.pumpAndSettle();

      // Bottom sheet should display options
      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('Tapping avatar when photo exists opens ProfilePhotoViewPage with zoom & actions', (tester) async {
      // Set initial photo
      await prefs.setString('photo_guest', base64Encode(transparentPng));
      await prefs.setString('nickname_guest', 'CyberRunner');

      await tester.pumpWidget(
        createTestWidget(
          prefs: prefs,
          initialPhoto: transparentPng,
          initialNickname: 'CyberRunner',
        ),
      );
      await tester.pumpAndSettle();

      // Tap on avatar
      final avatarFinder = find.byType(InkWell).first;
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // We should be on ProfilePhotoViewPage
      expect(find.byType(ProfilePhotoViewPage), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Tap delete button in view page
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Remove photo?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should pop back to ProfilePage and photo is removed
      expect(find.byType(ProfilePhotoViewPage), findsNothing);
      expect(prefs.getString('photo_guest'), isNull);
    });

    testWidgets('ProfilePhotoCropPage renders WhatsApp-style crop UI with rotate and done', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfilePhotoCropPage(imageBytes: transparentPng),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(find.byType(ProfilePhotoCropPage), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Crop Photo'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap rotate button
      final rotateBtn = find.byIcon(Icons.rotate_90_degrees_cw_outlined).first;
      await tester.tap(rotateBtn);
      await tester.pump();

      // Tap Done button
      await tester.runAsync(() async {
        await tester.tap(find.text('Done'));
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    });
  });
}

