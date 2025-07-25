import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/clear_sky_app.dart';
import 'package:clearsky_photo_reports/screens/splash_screen.dart';
import 'package:clearsky_photo_reports/screens/login_screen.dart';
import 'package:clearsky_photo_reports/screens/home_screen.dart';
import 'firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });

  testWidgets('Splash screen navigates after initialization', (tester) async {
    await tester.pumpWidget(const ClearSkyApp());

    // Verify splash screen shows initially
    expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for the delayed navigation in SplashScreen.initState
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    final loginFinder = find.byType(LoginScreen);
    final homeFinder = find.byType(HomeScreen);
    expect(loginFinder.evaluate().isNotEmpty || homeFinder.evaluate().isNotEmpty, isTrue);
  });
}
