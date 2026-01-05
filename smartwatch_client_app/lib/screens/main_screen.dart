import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartwatch_client_app/bloc/door_discovery_bloc.dart';
import 'package:smartwatch_client_app/bloc/door_discovery_event.dart';
import 'package:smartwatch_client_app/bloc/door_discovery_state.dart';
import 'package:smartwatch_client_app/bloc/door_unlock_bloc.dart';
import 'package:smartwatch_client_app/bloc/door_unlock_event.dart';
import 'package:smartwatch_client_app/bloc/door_unlock_state.dart';
import 'package:smartwatch_client_app/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DoorDiscoveryBloc()
            ..add(const StartScanRequested()),
        ),
        BlocProvider(
          create: (context) => DoorUnlockBloc(),
        ),
      ],
      child: PopScope(
        canPop: _currentPage == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentPage > 0) {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildMainPage(),
                  SettingsScreen(
                    onReset: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: _buildPageIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  Widget _buildMainPage() {
    return BlocListener<DoorUnlockBloc, DoorUnlockState>(
      listener: (context, unlockState) {
        if (unlockState is DoorUnlockSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text('${unlockState.doorName} unlocked'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              context.read<DoorDiscoveryBloc>().add(const StartScanRequested());
            }
          });
        } else if (unlockState is DoorUnlockFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(child: Text(unlockState.error)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              context.read<DoorDiscoveryBloc>().add(const StartScanRequested());
            }
          });
        }
      },
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: BlocBuilder<DoorDiscoveryBloc, DoorDiscoveryState>(
              builder: (context, discoveryState) {
                return BlocBuilder<DoorUnlockBloc, DoorUnlockState>(
                  builder: (context, unlockState) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDoorDisplay(discoveryState, unlockState),
                        const SizedBox(height: 20),
                        _buildActionButton(discoveryState, unlockState, context),
                        const SizedBox(height: 8),
                        _buildHintText(context),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoorDisplay(
    DoorDiscoveryState discoveryState,
    DoorUnlockState unlockState,
  ) {
    if (unlockState is DoorUnlockInProgress) {
      return Column(
        children: [
          const SizedBox(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 12),
          Text(
            unlockState.status,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    }

    if (unlockState is DoorUnlockSuccess) {
      return Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 32,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          Text(
            unlockState.doorName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    if (discoveryState is DoorDiscoveryScanning) {
      final nearestDoor = discoveryState.nearestDoor;
      if (nearestDoor != null) {
        return Column(
          children: [
            Icon(
              Icons.door_front_door,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              nearestDoor.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Signal: ${nearestDoor.rssi} dBm',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Scanning for doors...',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      }
    }

    if (discoveryState is DoorDiscoveryError) {
      return Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            discoveryState.message,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        Icon(
          Icons.door_front_door_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'No doors nearby',
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    DoorDiscoveryState discoveryState,
    DoorUnlockState unlockState,
    BuildContext context,
  ) {
    if (unlockState is DoorUnlockInProgress) {
      return OutlinedButton.icon(
        onPressed: () {
          context.read<DoorUnlockBloc>().add(const DoorUnlockCancelled());
        },
        icon: const Icon(Icons.close, size: 14),
        label: const Text('Cancel', style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    if (discoveryState is DoorDiscoveryError) {
      return FilledButton.icon(
        onPressed: () {
          context.read<DoorDiscoveryBloc>().add(const StartScanRequested());
        },
        icon: const Icon(Icons.refresh, size: 14),
        label: const Text('Retry', style: TextStyle(fontSize: 12)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    if (discoveryState is DoorDiscoveryScanning) {
      final nearestDoor = discoveryState.nearestDoor;
      if (nearestDoor != null && unlockState is! DoorUnlockSuccess) {
        return FilledButton.icon(
          onPressed: () {
            context.read<DoorUnlockBloc>().add(
                  DoorUnlockRequested(nearestDoor.deviceId, nearestDoor.name),
                );
          },
          icon: const Icon(Icons.lock_open, size: 14),
          label: const Text('Unlock', style: TextStyle(fontSize: 13)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        );
      }
    }

    if (unlockState is DoorUnlockSuccess) {
      return FilledButton.icon(
        onPressed: () {
          context.read<DoorUnlockBloc>().add(const DoorUnlockCancelled());
        },
        icon: const Icon(Icons.refresh, size: 14),
        label: const Text('Done', style: TextStyle(fontSize: 12)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHintText(BuildContext context) {
    return Text(
      'Swipe left for settings',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
