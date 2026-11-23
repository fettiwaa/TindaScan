import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/router/route_guard.dart';
import 'package:tindascan/features/auth/domain/session.dart';
import 'package:tindascan/shared/models/user_role.dart';

import '../../helpers/mocks.dart';

void main() {
  group('RouteGuard.canAccess', () {
    test('owner can open everything', () {
      for (final path in [
        AppRoutes.staff,
        AppRoutes.reports,
        AppRoutes.productNew,
        AppRoutes.productEdit('p1'),
      ]) {
        expect(
          RouteGuard.canAccess(UserRole.owner, path),
          isTrue,
          reason: path,
        );
      }
    });

    test('staff can open sell, product lookup and profile', () {
      for (final path in [
        AppRoutes.home,
        AppRoutes.sell,
        AppRoutes.products,
        AppRoutes.productDetail('p1'),
        AppRoutes.profile,
        AppRoutes.scan,
        AppRoutes.sellReceipt,
      ]) {
        expect(
          RouteGuard.canAccess(UserRole.staff, path),
          isTrue,
          reason: path,
        );
      }
    });

    test('staff are blocked from owner areas', () {
      for (final path in [
        AppRoutes.staff,
        AppRoutes.staffNew,
        AppRoutes.reports,
        AppRoutes.dashboard,
        AppRoutes.stock,
        AppRoutes.alerts,
        AppRoutes.settings,
        AppRoutes.productNew,
        AppRoutes.productEdit('p1'),
        AppRoutes.productHistory('p1'),
        AppRoutes.productStock('p1'),
        '/productsX',
      ]) {
        expect(
          RouteGuard.canAccess(UserRole.staff, path),
          isFalse,
          reason: path,
        );
      }
    });
  });

  group('RouteGuard.redirect', () {
    test('loading goes to splash', () {
      expect(RouteGuard.redirect(null, AppRoutes.home), AppRoutes.splash);
      expect(
        RouteGuard.redirect(const SessionLoading(), AppRoutes.splash),
        isNull,
      );
    });

    test('signed out before setup goes to setup, after setup to login', () {
      expect(
        RouteGuard.redirect(
          const SessionSignedOut(setupCompleted: false),
          AppRoutes.login,
        ),
        AppRoutes.setup,
      );
      expect(
        RouteGuard.redirect(
          const SessionSignedOut(setupCompleted: true),
          AppRoutes.staff,
        ),
        AppRoutes.login,
      );
    });

    test('failed setup check shows the connection issue screen', () {
      expect(
        RouteGuard.redirect(
          SessionSetupCheckFailed(Exception()),
          AppRoutes.login,
        ),
        AppRoutes.connectionIssue,
      );
    });

    test('missing profile stays in setup or shows account issue', () {
      expect(
        RouteGuard.redirect(
          const SessionMissingProfile(uid: 'u', setupCompleted: false),
          AppRoutes.setup,
        ),
        isNull,
      );
      expect(
        RouteGuard.redirect(
          const SessionMissingProfile(uid: 'u', setupCompleted: true),
          AppRoutes.home,
        ),
        AppRoutes.accountIssue,
      );
    });

    test('signed-in users leave auth screens and forbidden routes', () {
      const staff = SessionSignedIn(testStaff);
      expect(RouteGuard.redirect(staff, AppRoutes.login), AppRoutes.sell);
      expect(RouteGuard.redirect(staff, AppRoutes.reports), AppRoutes.sell);
      expect(RouteGuard.redirect(staff, AppRoutes.more), AppRoutes.sell);
      expect(RouteGuard.redirect(staff, AppRoutes.dashboard), AppRoutes.sell);
      expect(RouteGuard.redirect(staff, AppRoutes.sell), isNull);
      expect(
        RouteGuard.redirect(
          const SessionSignedIn(testOwner),
          AppRoutes.reports,
        ),
        isNull,
      );
    });

    test('home lands owners on Dashboard and staff on Sell', () {
      expect(
        RouteGuard.redirect(const SessionSignedIn(testOwner), AppRoutes.home),
        AppRoutes.dashboard,
      );
      expect(
        RouteGuard.redirect(const SessionSignedIn(testStaff), AppRoutes.home),
        AppRoutes.sell,
      );
    });
  });
}
