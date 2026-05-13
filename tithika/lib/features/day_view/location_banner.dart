import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/app_location.dart';
import '../../state/providers.dart';
import '../shared/city_picker_sheet.dart';

/// Shown at the top of the Day View when no location has been explicitly set.
/// Tapping it opens the city picker sheet; selecting a city saves it and
/// dismisses the banner automatically (locationIsSetProvider becomes true).
class LocationBanner extends ConsumerWidget {
  const LocationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationSet = ref.watch(locationIsSetProvider);
    if (locationSet) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<AppLocation>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CityPickerSheet(),
        );
        if (selected != null) {
          await ref.read(appSettingsProvider.notifier).setLocation(selected);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: TithikaColors.festival.withAlpha(26),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, size: 16, color: TithikaColors.festival),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap to set your location — currently showing Ujjain',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TithikaColors.festival,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: TithikaColors.festival),
          ],
        ),
      ),
    );
  }
}

