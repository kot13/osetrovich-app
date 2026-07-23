import 'package:flutter/material.dart';
import 'package:osetrovich/features/home/domain/home_loyalty_status_ui_model.dart';
import 'package:osetrovich/features/home/domain/home_profile_slot_ui_state.dart';
import 'package:osetrovich/features/home/presentation/home_auth_button.dart';
import 'package:osetrovich/features/home/presentation/home_loyalty_status_card.dart';
import 'package:osetrovich/features/home/presentation/home_loyalty_status_card_skeleton.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

class HomeProfileSlot extends StatelessWidget {
  const HomeProfileSlot({required this.mode, this.profile, super.key});

  final HomeProfileSlotMode mode;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      HomeProfileSlotMode.guestAuth => const HomeAuthButton(),
      HomeProfileSlotMode.hidden => const SizedBox.shrink(),
      HomeProfileSlotMode.loading => const HomeLoyaltyStatusCardSkeleton(),
      HomeProfileSlotMode.loyalty => HomeLoyaltyStatusCard(
        model: buildHomeLoyaltyStatusUiModel(profile!),
      ),
    };
  }
}
