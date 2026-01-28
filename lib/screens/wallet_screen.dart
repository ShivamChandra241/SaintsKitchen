import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:srm_kitchen/providers/user_provider.dart';
import 'package:srm_kitchen/models/wallet_transaction.dart';
import 'package:srm_kitchen/theme/theme_provider.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _showDepositDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DepositSheet(),
    );
  }

  void _showTxnDetails(BuildContext context, WalletTransaction t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Transaction Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row("Type", t.title),
            _row("Amount", "₹${t.amount.toInt()}"),
            _row("Method", t.method),
            if (t.meta != null) _row("Info", t.meta!),
            _row("Date", DateFormat('dd MMM yyyy, hh:mm a').format(t.date)),
            _row("Txn ID", t.id),
            const SizedBox(height: 10),
            const Text("Status: Successful",
                style: TextStyle(color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text("$k:")),
            Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: Consumer2<UserProvider, ThemeProvider>(
        builder: (context, user, theme, _) => Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: theme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6200EA).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10))
                ]
              ),
              child: Stack(
                children: [
                   Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.blur_on, size: 150, color: Colors.white.withOpacity(0.1)),
                   ),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "SRM PAY",
                            style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2),
                          ),
                          Icon(Icons.wifi_tethering, color: Colors.white.withOpacity(0.8)),
                        ],
                      ),
                       const SizedBox(height: 30),
                       const Text("Current Balance", style: TextStyle(color: Colors.white70)),
                       Row(
                         children: [
                           Text(
                             "₹${user.walletBalance.toInt()}",
                             style: const TextStyle(
                               color: Colors.white,
                               fontSize: 40,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 30),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(user.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                           Text(user.id, style: const TextStyle(color: Colors.white70)),
                         ],
                       )
                     ],
                   )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _showDepositDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text("ADD MONEY"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  )
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: user.transactions.length,
                  itemBuilder: (c, i) {
                    final t = user.transactions[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 5),
                      onTap: () => _showTxnDetails(context, t),
                      leading: CircleAvatar(
                        backgroundColor: t.isCredit ? Colors.green[50] : Colors.red[50],
                        child: Icon(
                          t.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: t.isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('dd MMM, hh:mm a').format(t.date)),
                      trailing: Text(
                        "${t.isCredit ? '+' : '-'} ₹${t.amount.toInt()}",
                        style: TextStyle(
                          color: t.isCredit ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DepositSheet extends StatefulWidget {
  const DepositSheet({super.key});
  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  int _method = 0;
  final _amountCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _pay() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    await Future.delayed(const Duration(seconds: 2));

    final meta = _method == 0
        ? "Card ****${_cardCtrl.text.padLeft(16, '0').substring(12)}"
        : _upiCtrl.text;

    final user = Provider.of<UserProvider>(context, listen: false);
    await user.addMoney(double.parse(_amountCtrl.text), _method == 0 ? "Card" : "UPI", meta);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Money Added!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 50, height: 5,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(height: 20),
        const Text("Top-up Wallet",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(children: [
          ChoiceChip(
              label: const Text("Debit Card"),
              selected: _method == 0,
              onSelected: (b) => setState(() => _method = 0),
              selectedColor: const Color(0xFF6200EA),
              labelStyle: TextStyle(color: _method == 0 ? Colors.white : null),
          ),
          const SizedBox(width: 10),
          ChoiceChip(
              label: const Text("UPI"),
              selected: _method == 1,
              onSelected: (b) => setState(() => _method = 1),
              selectedColor: const Color(0xFF6200EA),
              labelStyle: TextStyle(color: _method == 1 ? Colors.white : null),
          ),
        ]),
        const SizedBox(height: 20),
        TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
                labelText: "Amount",
                prefixText: "₹ ",
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
        const SizedBox(height: 15),

        if (_method == 0) ...[
          TextField(
              controller: _cardCtrl,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: InputDecoration(
                  labelText: "Card Number",
                  counterText: "",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _expiryCtrl,
                    decoration: InputDecoration(
                        labelText: "MM/YY",
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))),
            const SizedBox(width: 15),
            Expanded(
                child: TextField(
                    controller: _cvvCtrl,
                    obscureText: true,
                    maxLength: 3,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "CVV",
                        counterText: "",
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))),
          ]),
          const SizedBox(height: 15),
          TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: "Cardholder Name",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
        ],

        if (_method == 1)
          TextField(
              controller: _upiCtrl,
              decoration: InputDecoration(
                  labelText: "UPI ID (e.g. name@okaxis)",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),

        const SizedBox(height: 30),
        SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: _pay,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("PROCEED TO PAY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      ]),
    );
  }
}
