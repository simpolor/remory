import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String label;
  final int? count;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.label,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    );

    return IntrinsicWidth(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10), // 타임라인과 동일하게
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)), // 타임라인과 동일
              color: Colors.grey, // 타임라인과 동일한 회색
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('#$label', style: textStyle),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4), // 진한 회색 배경
                      borderRadius: BorderRadius.circular(999), // 완전 동그랗게
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600, // 조금 더 굵게
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}