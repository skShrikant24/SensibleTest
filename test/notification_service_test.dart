import 'package:flutter_test/flutter_test.dart';
import 'package:grabitt/services/notification_service.dart';

void main() {
  group('NotificationService.filterNotificationsToShow', () {
    test('returns only unseen orders while preserving the newest ones', () {
      final entries = [
        {
          'has_notification': true,
          'order_id': '2600',
          'title': 'Vendor accepted',
          'message': 'Order 2600 accepted',
        },
        {
          'has_notification': true,
          'order_id': '2607',
          'title': 'Vendor accepted',
          'message': 'Order 2607 accepted',
        },
        {
          'has_notification': true,
          'order_id': '2609',
          'title': 'Vendor accepted',
          'message': 'Order 2609 accepted',
        },
      ];

      final result = NotificationService.filterNotificationsToShow(entries, {'2600'});

      expect(result.map((entry) => entry['order_id']), ['2607', '2609']);
    });

    test('skips entries without a notification flag or an empty order id', () {
      final entries = [
        {
          'has_notification': false,
          'order_id': '2600',
          'title': 'Vendor accepted',
          'message': 'Order 2600 accepted',
        },
        {
          'has_notification': true,
          'order_id': '',
          'title': 'Vendor accepted',
          'message': 'Order without id',
        },
        {
          'has_notification': true,
          'order_id': '2610',
          'title': 'Vendor accepted',
          'message': 'Order 2610 accepted',
        },
      ];

      final result = NotificationService.filterNotificationsToShow(entries, {});

      expect(result.map((entry) => entry['order_id']), ['2610']);
    });

    test('allows later states for the same order when the status changes', () {
      final entries = [
        {
          'has_notification': true,
          'order_id': '2619',
          'order_status': 'accepted',
          'title': 'Order Accepted',
          'message': 'Your order #2619 has been accepted by the vendor.',
        },
        {
          'has_notification': true,
          'order_id': '2619',
          'order_status': 'picked_up',
          'title': 'Order Picked Up',
          'message': 'Your order #2619 has been picked up and is on the way.',
        },
        {
          'has_notification': true,
          'order_id': '2619',
          'order_status': 'delivered',
          'title': 'Order Delivered',
          'message': 'Your order #2619 has been delivered successfully.',
        },
      ];

      final result = NotificationService.filterNotificationsToShow(entries, {'2619'});

      expect(result.map((entry) => entry['order_status']), ['picked_up', 'delivered']);
    });

    test('normalizes alternate pickup status names to the same notification state', () {
      final entries = [
        {
          'has_notification': true,
          'order_id': '2620',
          'order_status': 'pick_up',
          'title': 'Order Picked Up',
          'message': 'Your order #2620 has been picked up and is on the way.',
        },
        {
          'has_notification': true,
          'order_id': '2620',
          'order_status': 'picked_up',
          'title': 'Order Picked Up',
          'message': 'Your order #2620 has been picked up and is on the way.',
        },
      ];

      final result = NotificationService.filterNotificationsToShow(entries, {});

      expect(result.map((entry) => entry['order_status']), ['pick_up', 'picked_up']);
    });
  });
}
