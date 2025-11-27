import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/pin_setup_screen.dart';
import 'features/auth/presentation/pin_verification_screen.dart';
import 'features/device/presentation/device_registration_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppView();
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Use dynamic colors if available, otherwise use defaults
        final lightColorScheme = lightDynamic?.harmonized();
        final darkColorScheme = darkDynamic?.harmonized();

        return BlocProvider(
          create: (context) => AuthBloc()..add(AuthInitializeRequested()),
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              // Listen to auth state changes globally and handle navigation
              if (state is AuthUnauthenticated) {
                // User logged out or forgot PIN - reset navigation to root
                _navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AppInitializer()),
                  (route) => false,
                );
              }
            },
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'Aditus',
              theme: AppTheme.light(lightColorScheme),
              darkTheme: AppTheme.dark(darkColorScheme),
              themeMode: ThemeMode.system,
              debugShowCheckedModeBanner: false,
              home: const AppInitializer(),
              routes: {
                '/login': (context) => const LoginScreen(),
                '/pin-setup': (context) => const PinSetupScreen(),
                '/pin-verification': (context) => const PinVerificationScreen(),
                '/device-registration': (context) => const DeviceRegistrationScreen(),
                '/home': (context) => const HomeScreen(),
              },
            ),
          ),
        );
      },
    );
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitializing || state is AuthInitial) {
          // Show loading screen while determining route
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthUnauthenticated) {
          // User needs to login
          return const LoginScreen();
        }

        if (state is AuthSuccess) {
          // User is authenticated, determine next screen based on onboarding status
          return FutureBuilder<Widget>(
            future: AppRouter.determineInitialRoute(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            context.read<AuthBloc>().add(AuthInitializeRequested());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return snapshot.data ?? const LoginScreen();
            },
          );
        }

        if (state is AuthFailure) {
          // Authentication failed, show login
          return const LoginScreen();
        }

        // Default to login screen
        return const LoginScreen();
      },
    );
  }
}
