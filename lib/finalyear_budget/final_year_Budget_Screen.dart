import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FinalYearBudgetScreen extends StatefulWidget {
  const FinalYearBudgetScreen({super.key});

  @override
  State<FinalYearBudgetScreen> createState() => _FinalYearBudgetScreenState();
}

class _FinalYearBudgetScreenState extends State<FinalYearBudgetScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  DateTime? selectedDate;

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  //  Add or update player fund safely
  Future<void> addPlayerFund(String name, int amount, DateTime date) async {
    final playerDoc =
    FirebaseFirestore.instance.collection("players").doc(name);

    try {
      await playerDoc.set({
        "name": name,
        "annualFundPaid": FieldValue.increment(amount),
        "totalFund": FieldValue.increment(amount),
        "lastPaidDate": date,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fund added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add fund: $e")),
      );
    }
  }

  //Delete player fund
  Future<void> deletePlayerFund(String playerId) async {
    try {
      await FirebaseFirestore.instance.collection("players").doc(playerId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Player budget deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete: $e")),
      );
    }
  }

  //Pick date
  Future<void> pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Final Year Budget"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Add new fund
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Player Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => pickDate(context),
                  child: Text(
                    selectedDate == null
                        ? "Pick Date"
                        : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        amountController.text.trim().isEmpty ||
                        selectedDate == null) return;

                    final name = nameController.text.trim();
                    final amount = int.tryParse(amountController.text.trim()) ?? 0;

                    await addPlayerFund(name, amount, selectedDate!);

                    nameController.clear();
                    amountController.clear();
                    setState(() {
                      selectedDate = null;
                    });
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Players list + total fund
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("players")
                  .orderBy("name")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final players = snapshot.data!.docs;

                int totalFund = 0;
                for (var player in players) {
                  final data = player.data() as Map<String, dynamic>;
                  totalFund += (data['annualFundPaid'] ?? 0) as int;
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final playerId = player.id;
                          final data = player.data() as Map<String, dynamic>;
                          final name = data['name'] ?? "Unknown";
                          final paid = (data['annualFundPaid'] ?? 0) as int;

                          final lastDateTimestamp = data['lastPaidDate'];
                          final lastDate = (lastDateTimestamp != null &&
                              lastDateTimestamp is Timestamp)
                              ? lastDateTimestamp.toDate()
                              : null;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Paid: $paid   |   Date: ${lastDate != null ? "${lastDate.day}-${lastDate.month}-${lastDate.year}" : "N/A"}",
                              ),
                              trailing: IconButton(
                                icon:
                                const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title:
                                      const Text("Delete Player Budget"),
                                      content: Text(
                                          "Are you sure you want to delete $name’s budget record?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          onPressed: () async {
                                            await deletePlayerFund(playerId);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    //Total Fund container
                    Container(
                      color: Colors.red,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Total Fund Collected: $totalFund",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
