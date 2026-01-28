import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      "title": "TEAM FANTASTIC 6",
      "subtitle": "Built for SRM, by SRM.",
      "content": [
        "Mohammed Shameem J",
        "Aryaman Yadav",
        "Shivam Chandra",
        "Krishna Santhanam",
      ],
      "icon": Icons.groups
    },
    {
      "title": "THE PROBLEM",
      "subtitle": "Canteen Chaos (40 mins)",
      "content": [
        "Overcrowding during break",
        "Long queues for payment",
        "Food runs out quickly",
        "Cash fumbling & delays",
      ],
      "icon": Icons.warning_amber_rounded
    },
    {
      "title": "THE SOLUTION",
      "subtitle": "SRM KITCHEN v2.0",
      "content": [
        "Pre-order from Class 📱",
        "Express Menu (Ready < 2mins) ⚡",
        "Digital Wallet Payment 💳",
        "Live Order Tracking 🔔",
      ],
      "icon": Icons.check_circle_outline
    },
    {
      "title": "TECH STACK",
      "subtitle": "Modern & Scalable",
      "content": [
        "Flutter (Cross Platform)",
        "Hive (Local NoSQL DB)",
        "Provider (State Management)",
        "Ready for Cloud Scaling ☁️",
      ],
      "icon": Icons.code
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final s = _slides[index];
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black,
                      index % 2 == 0 ? const Color(0xFF6200EA).withOpacity(0.4) : const Color(0xFFFF5722).withOpacity(0.4)
                    ]
                  )
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s['icon'], size: 80, color: Colors.white),
                    const SizedBox(height: 40),
                    Text(s['title'], style: GoogleFonts.bebasNeue(fontSize: 50, color: Colors.white, letterSpacing: 2)),
                    Text(s['subtitle'], style: GoogleFonts.poppins(fontSize: 20, color: Colors.white70)),
                    const SizedBox(height: 40),
                    ... (s['content'] as List<String>).map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 15),
                          Text(t, style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _page == i ? 30 : 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _page == i ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(5)
                ),
              )),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}
