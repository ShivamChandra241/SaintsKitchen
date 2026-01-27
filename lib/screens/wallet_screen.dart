import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:srm_kitchen/providers/user_provider.dart';
import 'package:srm_kitchen/models/wallet_transaction.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _showDepositDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
      body: Consumer<UserProvider>(
        builder: (context, user, _) => Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6200EA), Color(0xFF651FFF)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Balance",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    "₹${user.walletBalance.toInt()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showDepositDialog(context),
                  child: const Text("ADD MONEY"),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: user.transactions.length,
                itemBuilder: (c, i) {
                  final t = user.transactions[i];
                  return ListTile(
                    onTap: () => _showTxnDetails(context, t),
                    leading: Icon(
                      t.isCredit
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: t.isCredit ? Colors.green : Colors.red,
                    ),
                    title: Text(t.title),
                    subtitle: Text(DateFormat('dd MMM').format(t.date)),
                    trailing: Text(
                      "${t.isCredit ? '+' : '-'} ₹${t.amount.toInt()}",
                      style: TextStyle(
                        color: t.isCredit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
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
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Add Money",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(children: [
          ChoiceChip(
              label: const Text("Card"),
              selected: _method == 0,
              onSelected: (b) => setState(() => _method = 0)),
          const SizedBox(width: 10),
          ChoiceChip(
              label: const Text("UPI"),
              selected: _method == 1,
              onSelected: (b) => setState(() => _method = 1)),
        ]),
        const SizedBox(height: 15),
        TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: "Amount (₹)", border: OutlineInputBorder())),
        const SizedBox(height: 10),

        if (_method == 0) ...[
          TextField(
              controller: _cardCtrl,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: const InputDecoration(
                  labelText: "Card Number",
                  counterText: "",
                  border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _expiryCtrl,
                    decoration: const InputDecoration(
                        labelText: "MM/YY",
                        border: OutlineInputBorder()))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _cvvCtrl,
                    obscureText: true,
                    maxLength: 3,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "CVV",
                        counterText: "",
                        border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 10),
          TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: "Cardholder Name",
                  border: OutlineInputBorder())),
        ],

        if (_method == 1)
          TextField(
              controller: _upiCtrl,
              decoration: const InputDecoration(
                  labelText: "UPI ID (e.g. name@upi)",
                  border: OutlineInputBorder())),

        const SizedBox(height: 20),
        SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
                onPressed: _pay,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("PAY NOW"))),
        const SizedBox(height: 20),
      ]),
    );
  }
}
