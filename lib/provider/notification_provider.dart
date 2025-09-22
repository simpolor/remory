
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/provider/state/notification_toggle.dart';

final notificationEnabledProvider = StateNotifierProvider<NotificationToggle, bool>((ref) {
  return NotificationToggle(ref);
});