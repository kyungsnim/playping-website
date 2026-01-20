import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/region_provider.dart';

/// 리전 필터 드롭다운 위젯
class RegionFilter extends ConsumerWidget {
  const RegionFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(selectedRegionProvider);
    final allRegions = ref.watch(allRegionsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getRegionColor(selectedRegion).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRegionColor(selectedRegion).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud,
            size: 18,
            color: _getRegionColor(selectedRegion),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<FirestoreRegion>(
              value: selectedRegion,
              isDense: true,
              items: allRegions.map((region) {
                return DropdownMenuItem<FirestoreRegion>(
                  value: region,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getRegionFlag(region),
                      const SizedBox(width: 8),
                      Text(
                        region.displayName,
                        style: TextStyle(
                          fontWeight: region == selectedRegion
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(selectedRegionProvider.notifier).state = value;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRegionColor(FirestoreRegion region) {
    switch (region) {
      case FirestoreRegion.seoul:
        return Colors.blue;
      case FirestoreRegion.europe:
        return Colors.green;
      case FirestoreRegion.us:
        return Colors.orange;
    }
  }

  Widget _getRegionFlag(FirestoreRegion region) {
    String flag;
    switch (region) {
      case FirestoreRegion.seoul:
        flag = '🇰🇷';
        break;
      case FirestoreRegion.europe:
        flag = '🇪🇺';
        break;
      case FirestoreRegion.us:
        flag = '🇺🇸';
        break;
    }
    return Text(flag, style: const TextStyle(fontSize: 16));
  }
}

/// 리전 필터 칩 버튼 스타일
class RegionFilterChips extends ConsumerWidget {
  const RegionFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(selectedRegionProvider);
    final allRegions = ref.watch(allRegionsProvider);

    return Wrap(
      spacing: 8,
      children: allRegions.map((region) {
        final isSelected = region == selectedRegion;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getRegionFlag(region),
              const SizedBox(width: 4),
              Text(region.displayName),
            ],
          ),
          selected: isSelected,
          onSelected: (_) {
            ref.read(selectedRegionProvider.notifier).state = region;
          },
          selectedColor: _getRegionColor(region).withValues(alpha: 0.2),
          checkmarkColor: _getRegionColor(region),
        );
      }).toList(),
    );
  }

  Color _getRegionColor(FirestoreRegion region) {
    switch (region) {
      case FirestoreRegion.seoul:
        return Colors.blue;
      case FirestoreRegion.europe:
        return Colors.green;
      case FirestoreRegion.us:
        return Colors.orange;
    }
  }

  Widget _getRegionFlag(FirestoreRegion region) {
    String flag;
    switch (region) {
      case FirestoreRegion.seoul:
        flag = '🇰🇷';
        break;
      case FirestoreRegion.europe:
        flag = '🇪🇺';
        break;
      case FirestoreRegion.us:
        flag = '🇺🇸';
        break;
    }
    return Text(flag, style: const TextStyle(fontSize: 14));
  }
}
