import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/core/error/fallback_error_screen.dart';
import 'package:feynman/core/providers/logger_provider.dart';

class ErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  Object? _error;
  FlutterExceptionHandler? _previousErrorHandler;
  String? _routeName;

  @override
  void initState() {
    super.initState();
    _previousErrorHandler = FlutterError.onError;
    FlutterError.onError = _handleFlutterError;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeName = ModalRoute.of(context)?.settings.name ?? 'unknown';
  }

  @override
  void dispose() {
    if (FlutterError.onError == _handleFlutterError) {
      FlutterError.onError = _previousErrorHandler;
    }
    super.dispose();
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    final logger = ref.read(loggerProvider);
    logger.error(
      'ErrorBoundary',
      'Caught Flutter error on $_routeName',
      details.exception,
      details.stack,
    );

    _previousErrorHandler?.call(details);

    // Defer setState to after the current build phase completes.
    // Calling setState synchronously here causes the '!_dirty' and
    // '_debugCurrentBuildTarget != null' framework assertions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _error = details.exception;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return FallbackErrorScreen(
        message: _error.toString(),
        onRetry: () {
          setState(() {
            _error = null;
          });
        },
      );
    }
    return widget.child;
  }
}
