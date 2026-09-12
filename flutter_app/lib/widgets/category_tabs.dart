import 'package:flutter/material.dart';
import '../constants/jio_colors.dart';
import '../constants/categories.dart';

class CategoryTabs extends StatelessWidget {
  final String activeCategoryId;
  final ValueChanged<String> onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.activeCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: JioColors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: JioColors.borderSubtle, width: 1),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: Categories.items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = Categories.items[index];
          final isActive = item.id == activeCategoryId;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: () => onCategorySelected(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive ? JioColors.jioBlue : JioColors.bgSecondary,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isActive ? JioColors.jioBlue : JioColors.borderDefault,
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: JioColors.jioBlue.withValues(alpha: 0.24),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: isActive ? Colors.white : JioColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? Colors.white : JioColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
