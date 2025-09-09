import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../../domain/entities/advertisement.dart';

class AdTypeSelector extends StatelessWidget {
  const AdTypeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ad Type:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (chatProvider.selectedAdType != null)
                  TextButton(
                    onPressed: () => chatProvider.setSelectedAdType(null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAdTypeChip(
                    context,
                    null,
                    'All',
                    Icons.all_inclusive,
                    chatProvider.selectedAdType == null,
                    () => chatProvider.setSelectedAdType(null),
                  ),
                  const SizedBox(width: 8),
                  ...AdType.values.map((adType) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildAdTypeChip(
                      context,
                      adType,
                      adType.displayName,
                      _getAdTypeIcon(adType),
                      chatProvider.selectedAdType == adType,
                      () => chatProvider.setSelectedAdType(adType),
                    ),
                  )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdTypeChip(
    BuildContext context,
    AdType? adType,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAdTypeIcon(AdType adType) {
    switch (adType) {
      case AdType.google:
        return Icons.search;
      case AdType.facebook:
        return Icons.facebook;
      case AdType.instagram:
        return Icons.camera_alt;
      case AdType.tiktok:
        return Icons.music_video;
      case AdType.youtube:
        return Icons.play_circle;
      case AdType.socialMedia:
        return Icons.share;
      case AdType.other:
        return Icons.more_horiz;
    }
  }
}
