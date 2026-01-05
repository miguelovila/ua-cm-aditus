import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/account/widgets/item_cluster.dart';
import 'package:smartphone_client_app/features/account/widgets/user_card.dart';
import 'package:smartphone_client_app/features/account/widgets/logout_dialog.dart';
import 'package:smartphone_client_app/features/account/presentation/change_pin_screen.dart';
import 'package:smartphone_client_app/features/account/presentation/change_password_screen.dart';
import 'package:smartphone_client_app/features/account/presentation/theme_selection_screen.dart';
import 'package:smartphone_client_app/features/account/presentation/bloc/bloc.dart';
import 'package:smartphone_client_app/features/device/presentation/my_devices_screen.dart';
import 'package:smartphone_client_app/features/group/presentation/my_groups_screen.dart';
import 'package:smartphone_client_app/features/smartwatch/presentation/smartwatch_pairing_screen.dart';
import 'package:smartphone_client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartphone_client_app/core/theme/theme_cubit.dart';
import 'package:smartphone_client_app/core/ui/snackbar_helper.dart';
import 'package:smartphone_client_app/core/ui/widgets/widgets.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AccountBloc()..add(const AccountInitializeRequested()),
      child: BlocListener<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is AccountLoggedOut) {
            // Trigger auth logout
            context.read<AuthBloc>().add(AuthLogoutRequested());
          } else if (state is AccountBiometricToggleError) {
            SnackbarHelper.showError(context, 'Authentication failed');
          } else if (state is AccountLoaded) {
            // Check if we came from toggling state
            final previousState = context.read<AccountBloc>().state;
            if (previousState is AccountBiometricToggling) {
              // Successfully toggled
              SnackbarHelper.showSuccess(
                context,
                state.biometricEnabled
                    ? '${state.biometricTypeName} enabled'
                    : '${state.biometricTypeName} disabled',
              );
            }
          }
        },
        child: BlocBuilder<AccountBloc, AccountState>(
          builder: (context, state) {
            if (state is AccountLoading) {
              return const LoadingState();
            }

            if (state is AccountError) {
              return ErrorState(
                title: 'Failed to load account settings',
                message: state.message.replaceAll('Exception: ', ''),
                onRetry: () => context.read<AccountBloc>().add(
                  const AccountInitializeRequested(),
                ),
              );
            }

            // Get account state for UI rendering
            final AccountLoaded? accountState = state is AccountLoaded
                ? state
                : state is AccountBiometricToggling ||
                      state is AccountLoggingOut
                ? null // Will get from bloc
                : null;

            final isLoggingOut = state is AccountLoggingOut;
            final isTogglingBiometric = state is AccountBiometricToggling;

            return _AccountContent(
              accountState: accountState,
              isLoggingOut: isLoggingOut,
              isTogglingBiometric: isTogglingBiometric,
            );
          },
        ),
      ),
    );
  }
}

class _AccountContent extends StatelessWidget {
  final AccountLoaded? accountState;
  final bool isLoggingOut;
  final bool isTogglingBiometric;

  const _AccountContent({
    required this.accountState,
    required this.isLoggingOut,
    required this.isTogglingBiometric,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // If account state is null, try to get the loaded state from context
    final AccountLoaded? loadedState =
        accountState ??
        (context.read<AccountBloc>().state is AccountLoaded
            ? context.read<AccountBloc>().state as AccountLoaded
            : null);

    if (loadedState == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: EdgeInsets.only(
        top: statusBarHeight + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      children: [
        // User Profile Card
        const UserCard(),

        const SizedBox(height: 24),

        // Account Information Section
        ItemCluster(
          title: 'Account',
          children: [
            ClusterItem(
              icon: Icons.group,
              title: 'My Groups',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyGroupsScreen(),
                  ),
                );
              },
            ),
            ClusterItem(
              icon: Icons.devices,
              title: 'My Devices',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyDevicesScreen(),
                  ),
                );
              },
            ),
            ClusterItem(
              icon: Icons.watch,
              title: 'Pair Smartwatch',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SmartWatchPairingScreen(),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Security Section
        ItemCluster(
          title: 'Security',
          children: [
            ClusterItem(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            ClusterItem(
              icon: Icons.pin,
              title: 'Change PIN',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangePinScreen(),
                  ),
                );
              },
            ),
            ClusterItem(
              icon: Icons.fingerprint,
              title: loadedState.biometricTypeName,
              subtitle: loadedState.biometricsAvailable
                  ? null
                  : const Text('Not available on this device'),
              trailing: Switch(
                value: loadedState.biometricEnabled,
                onChanged:
                    loadedState.biometricsAvailable && !isTogglingBiometric
                    ? (value) {
                        context.read<AccountBloc>().add(
                          AccountBiometricToggled(value),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Preferences Section
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return ItemCluster(
              title: 'Preferences',
              children: [
                ClusterItem(
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: Text(themeState.preferences.themeModeDisplayName),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ThemeSelectionScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // About Section
        ItemCluster(
          title: 'About',
          children: [
            const ClusterItem(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: Text('1.0.0'),
              trailing: SizedBox.shrink(), // No arrow for non-tappable item
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: isLoggingOut ? null : () => _showLogoutDialog(context),
            icon: isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(isLoggingOut ? 'Logging out...' : 'Logout'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showLogoutDialog(context);
    if (confirmed && context.mounted) {
      context.read<AccountBloc>().add(const AccountLogoutRequested());
    }
  }
}
