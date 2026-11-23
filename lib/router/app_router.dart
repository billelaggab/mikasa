import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mikasa/screens/highlights_screen.dart';
import 'package:mikasa/screens/library_screen.dart';
import 'package:mikasa/screens/pdf_reader_screen.dart';

/// مسارات التطبيق في مكان واحد (بدل نصوص متناثرة في الشاشات).
class AppRoutes {
  const AppRoutes._();

  static const String library = '/';
  static const String allHighlights = '/highlights';
  static const String readerName = 'reader';

  static String reader(String bookId) => '/reader/$bookId';

  /// يفتح الكتاب على صفحة محددة (تُستخدم عند الانتقال من اقتباس).
  static String readerAtPage(String bookId, int page) => '/reader/$bookId?page=$page';

  static String bookHighlights(String bookId) => '/reader/$bookId/highlights';
}

/// انتقال ناعم بين الشاشات (تلاشي + انزلاق بسيط).
CustomTransitionPage<void> _fadeSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.library,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.library,
        name: 'library',
        pageBuilder: (BuildContext context, GoRouterState state) => _fadeSlidePage(
          key: state.pageKey,
          child: const LibraryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.allHighlights,
        name: 'allHighlights',
        pageBuilder: (BuildContext context, GoRouterState state) => _fadeSlidePage(
          key: state.pageKey,
          child: const HighlightsScreen(),
        ),
      ),
      GoRoute(
        path: '/reader/:bookId',
        name: AppRoutes.readerName,
        pageBuilder: (BuildContext context, GoRouterState state) => _fadeSlidePage(
          key: state.pageKey,
          child: PdfReaderScreen(
            bookId: state.pathParameters['bookId'] ?? '',
            initialPage: int.tryParse(state.uri.queryParameters['page'] ?? ''),
          ),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'highlights',
            name: 'bookHighlights',
            pageBuilder: (BuildContext context, GoRouterState state) => _fadeSlidePage(
              key: state.pageKey,
              child: HighlightsScreen(bookId: state.pathParameters['bookId']),
            ),
          ),
        ],
      ),
    ],
  );
}
