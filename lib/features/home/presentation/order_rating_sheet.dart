import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';

class OrderRatingSheet extends StatefulWidget {
  const OrderRatingSheet({super.key, required this.onSubmit});

  final void Function(int stars, String? comment) onSubmit;

  @override
  State<OrderRatingSheet> createState() => _OrderRatingSheetState();
}

Future<void> showOrderRatingSheet(
  BuildContext context, {
  required void Function(int stars, String? comment) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: OrderRatingSheet(onSubmit: onSubmit),
        ),
  );
}

class _OrderRatingSheetState extends State<OrderRatingSheet> {
  int _selectedStars = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.homeOrderRatingTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _selectedStars = star),
                  icon: Icon(
                    star <= _selectedStars ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 36,
                  ),
                );
              }),
            ),
            TextField(
              controller: _commentController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: AppStrings.cartCommentLabel,
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.homeOrderRatingCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.dark,
                    ),
                    onPressed:
                        _selectedStars == 0
                            ? null
                            : () {
                              widget.onSubmit(
                                _selectedStars,
                                _commentController.text,
                              );
                              Navigator.of(context).pop();
                            },
                    child: const Text(AppStrings.homeOrderRatingSubmit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
