import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared motion primitives so animation feel stays consistent app-wide
/// instead of every screen hand-rolling its own durations/curves.

/// A fast fade+rise entrance for list items and cards. Cheap enough to use
/// on every item in a list without jank.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// A gentle scale+fade "pop" used for success states (delivery completed,
/// rating submitted) — one clear moment of delight, not a gimmick everywhere.
class PopIn extends StatefulWidget {
  final Widget child;
  const PopIn({super.key, required this.child});

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow)..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _controller, curve: AppMotion.pop);
    final fade = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: widget.child),
    );
  }
}

/// Standard fade+slide page route — used in place of the default Material
/// push for a slightly more premium feel without a heavyweight animations
/// package.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  AppPageRoute({required this.page})
      : super(
          transitionDuration: AppMotion.base,
          reverseTransitionDuration: AppMotion.base,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                    .animate(curved),
                child: child,
              ),
            );
          },
        );
}
