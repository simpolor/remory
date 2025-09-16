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
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            color: Colors.grey,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('#$label', style: textStyle),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${count}개', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}