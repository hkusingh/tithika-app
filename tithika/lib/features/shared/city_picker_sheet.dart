import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/app_location.dart';
import '../../services/providers.dart';

/// Modal bottom sheet for searching and selecting a city.
///
/// Returns the selected [AppLocation] via [Navigator.pop], or null if dismissed.
/// Callers are responsible for saving the selection and navigating.
class CityPickerSheet extends ConsumerStatefulWidget {
  const CityPickerSheet({super.key});

  @override
  ConsumerState<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<CityPickerSheet> {
  final _controller = TextEditingController();
  List<AppLocation> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onQuery());
  }

  @override
  void dispose() {
    _controller.removeListener(_onQuery);
    _controller.dispose();
    super.dispose();
  }

  void _onQuery() {
    ref.read(citySearchServiceProvider).whenData((svc) {
      final results = svc.search(_controller.text);
      if (mounted) setState(() => _results = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: colors.ink),
              cursorColor: colors.shukla,
              decoration: InputDecoration(
                hintText: 'Search city…',
                hintStyle: TextStyle(color: colors.inkMuted),
                prefixIcon: Icon(Icons.search, color: colors.inkSoft),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colors.inkMuted),
                        onPressed: _controller.clear,
                      )
                    : null,
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'No cities found',
                      style: TextStyle(color: colors.inkMuted),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: bottom + 16),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final city = _results[i];
                      return ListTile(
                        title: Text(city.cityName, style: TextStyle(color: colors.ink)),
                        trailing: Text(
                          city.country,
                          style: TextStyle(color: colors.inkMuted, fontSize: 12),
                        ),
                        onTap: () => Navigator.of(context).pop(city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
