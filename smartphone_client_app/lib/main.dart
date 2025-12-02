import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_preferences.dart';
import 'core/navigation/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/pin_setup_screen.dart';
import 'features/auth/presentation/pin_verification_screen.dart';
import 'features/device/presentation/device_registration_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/admin/group_management/presentation/bloc/group_management_bloc.dart';
import 'features/admin/group_management/presentation/screens/group_list_screen.dart';
import 'features/admin/group_management/presentation/screens/group_create_screen.dart';
import 'features/admin/group_management/presentation/screens/group_detail_screen.dart';
import 'features/admin/group_management/presentation/screens/group_edit_screen.dart';
import 'features/group/data/models/group.dart';
import 'features/admin/user_management/presentation/bloc/user_management_bloc.dart';
import 'features/admin/user_management/presentation/screens/user_list_screen.dart';
import 'features/admin/user_management/presentation/screens/user_create_screen.dart';
import 'features/admin/user_management/presentation/screens/user_detail_screen.dart';
import 'features/admin/user_management/presentation/screens/user_edit_screen.dart';
import 'features/auth/data/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(
          create: (context) => AuthBloc()..add(AuthInitializeRequested()),
        ),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  Widget _buildAdminGroupRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/admin/groups':
        return const GroupListScreen();
      case '/admin/groups/create':
        return const GroupCreateScreen();
      case '/admin/groups/detail':
        final groupId = settings.arguments as int;
        return GroupDetailScreen(groupId: groupId);
      case '/admin/groups/edit':
        final group = settings.arguments as Group;
        return GroupEditScreen(group: group);
      default:
        return const Scaffold(
          body: Center(child: Text('Route not found')),
        );
    }
  }

  Widget _buildAdminUserRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/admin/users':
        return const UserListScreen();
      case '/admin/users/create':
        return const UserCreateScreen();
      case '/admin/users/detail':
        final userId = settings.arguments as int;
        return UserDetailScreen(userId: userId);
      case '/admin/users/edit':
        final user = settings.arguments as User;
        return UserEditScreen(user: user);
      default:
        return const Scaffold(
          body: Center(child: Text('Route not found')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final preferences = themeState.preferences;

        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            // Determine color schemes based on preferences
            ColorScheme? lightColorScheme;
            ColorScheme? darkColorScheme;

            if (preferences.colorScheme == AppColorScheme.dynamic) {
              // Use Material You dynamic colors if available
              lightColorScheme = lightDynamic?.harmonized();
              darkColorScheme = darkDynamic?.harmonized();
            } else {
              // Use custom seed color
              final seedColor = preferences.seedColor!;
              lightColorScheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              );
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              );
            }

            return BlocListener<AuthBloc, AuthState>(
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
                themeMode: preferences.materialThemeMode,
                debugShowCheckedModeBanner: false,
                home: const AppInitializer(),
                routes: {
                  '/login': (context) => const LoginScreen(),
                  '/pin-setup': (context) => const PinSetupScreen(),
                  '/pin-verification': (context) =>
                      const PinVerificationScreen(),
                  '/device-registration': (context) =>
                      const DeviceRegistrationScreen(),
                  '/home': (context) => const HomeScreen(),
                },
                onGenerateRoute: (settings) {
                  // Handle admin group management routes with BLoC provider
                  if (settings.name?.startsWith('/admin/groups') ?? false) {
                    return MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => GroupManagementBloc(),
                        child: _buildAdminGroupRoute(settings),
                      ),
                      settings: settings,
                    );
                  }
                  // Handle admin user management routes with BLoC provider
                  if (settings.name?.startsWith('/admin/users') ?? false) {
                    return MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => UserManagementBloc(),
                        child: _buildAdminUserRoute(settings),
                      ),
                      settings: settings,
                    );
                  }
                  return null;
                },
              ),
            );
          },
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
            body: Center(child: CircularProgressIndicator()),
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
                  body: Center(child: CircularProgressIndicator()),
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
                            context.read<AuthBloc>().add(
                              AuthInitializeRequested(),
                            );
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
