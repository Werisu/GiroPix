import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Frase curta no topo quando o bruto do dia cruza a meta.
class MetaBatidaBanner {
  MetaBatidaBanner._();

  static OverlayEntry? _entry;

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry?.remove();
    _entry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _MetaBatidaBannerView(
        onDone: () {
          if (entry.mounted) entry.remove();
          if (identical(_entry, entry)) _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _MetaBatidaBannerView extends StatefulWidget {
  const _MetaBatidaBannerView({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_MetaBatidaBannerView> createState() => _MetaBatidaBannerViewState();
}

class _MetaBatidaBannerViewState extends State<_MetaBatidaBannerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(_fade);
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2400), _sair);
  }

  Future<void> _sair() async {
    if (!mounted) return;
    try {
      await _controller.reverse();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Material(
                    color: AppColors.surface,
                    elevation: 8,
                    shadowColor: context.accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: context.accent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: context.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Meta batida',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
