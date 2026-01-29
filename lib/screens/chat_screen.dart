import 'package:flutter/material.dart';

class ChatService {
  static Future<String> getResponse(String query) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate thinking
    query = query.toLowerCase();

    if (query.contains('menu') || query.contains('food')) {
      return "We have a variety of dishes! Check out the 'Express' section for quick bites or 'Java Green' for popular combos.";
    }
    if (query.contains('money') || query.contains('wallet') || query.contains('pay')) {
      return "You can add money to your wallet via UPI or Card in the Wallet tab. Payments are secure!";
    }
    if (query.contains('team') || query.contains('who')) {
      return "I was built by Team Fantastic 6 for SRM University students.";
    }
    if (query.contains('veg') || query.contains('vegan')) {
      return "Yes! You can use the 'Veg' filter toggle on the menu screen to see only vegetarian options.";
    }
    if (query.contains('problem') || query.contains('chaos')) {
      return "SRM Kitchen solves the canteen overcrowding problem by allowing you to pre-order food from your classroom.";
    }
    if (query.contains('hello') || query.contains('hi')) {
      return "Hello! I'm your SRM Kitchen assistant. How can I help you today?";
    }

    return "I'm still learning! Ask me about the menu, wallet, or our team.";
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "bot", "text": "Hi! I'm the SRM AI Assistant. Ask me anything!"}
  ];
  bool _typing = false;

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _typing = true;
    });
    _ctrl.clear();

    final response = await ChatService.getResponse(text);

    if (mounted) {
      setState(() {
        _typing = false;
        _messages.add({"role": "bot", "text": response});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!))
            ),
            child: Row(children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF6200EA),
                child: Icon(Icons.smart_toy, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text("SRM Assistant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF6200EA) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? Radius.zero : null,
                        bottomLeft: isUser ? null : Radius.zero
                      ),
                    ),
                    child: Text(msg['text']!, style: TextStyle(color: isUser ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          if (_typing)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Thinking...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, right: 20, top: 10
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: const Color(0xFF6200EA),
                child: IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Colors.white)),
              )
            ]),
          )
        ],
      ),
    );
  }
}
