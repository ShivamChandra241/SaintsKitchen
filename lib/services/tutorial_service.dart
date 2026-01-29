import 'package:flutter/material.dart';

class TutorialOverlay extends StatelessWidget {
  final VoidCallback onNext;
  final String text;
  final Rect targetRect;

  const TutorialOverlay({
    super.key,
    required this.onNext,
    required this.text,
    required this.targetRect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Background with Hole
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black54,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned.fromRect(
                rect: targetRect,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20), // Approx radius
                  ),
                ),
              ),
            ],
          ),
        ),

        // Spotlight Border
        Positioned.fromRect(
          rect: targetRect.inflate(5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.yellow, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 20)
              ]
            ),
          ),
        ),

        // Text & Button
        Positioned(
          top: targetRect.bottom + 20,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(text, style: const TextStyle(fontSize: 16, color: Colors.black)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: onNext,
                            child: const Text("NEXT STEP"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TutorialController {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, GlobalKey key, String text, VoidCallback onNext) {
    _overlayEntry?.remove();

    // Get Widget Position
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      onNext(); // Skip if widget not found
      return;
    }
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    _overlayEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        onNext: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          onNext();
        },
        text: text,
        targetRect: rect,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }
}
