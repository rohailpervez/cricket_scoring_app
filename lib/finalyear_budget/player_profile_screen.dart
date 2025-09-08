import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String playerId;

  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Player Profile"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("career")
            .doc(playerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundImage: (data["imageUrl"] != null && data["imageUrl"] != "")
                      ? NetworkImage(data["imageUrl"])
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: (data["imageUrl"] == null || data["imageUrl"] == "")
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 10),

                Text(
                  data["name"] ?? "No Name",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Role: ${data["role"] ?? "-"}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text("📞 Phone: ${data["phone"] ?? "N/A"}"),
                const Divider(thickness: 2),

                // Batting
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🏏 Batting Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Matches Played: ${data["matchesPlayed"] ?? 0}"),
                      Text("Runs: ${data["totalRuns"] ?? 0}"),
                      Text("Highest Score: ${data["highestScore"] ?? 0}"),
                      Text("50s: ${data["fifties"] ?? 0}"),
                      Text("100s: ${data["hundered"] ?? 0}"),
                      Text("Average: ${(data["average"] ?? 0).toStringAsFixed(2)}"),
                    ],
                  ),
                ),
                const Divider(),

                // Bowling
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🎯 Bowling Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Wickets: ${data["wickets"] ?? 0}"),
                      Text("Overs: ${data["overs"] ?? 0}"),
                      Text("Runs Conceded: ${data["runConceeded"] ?? 0}"),
                      Text("Best Figures: ${data["bestFigure"] ?? "-"}"),
                      Text("Economy: ${(data["economy"] ?? 0).toStringAsFixed(2)}"),
                    ],
                  ),
                ),
                const Divider(),

                // Funds
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("💰 Funds", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Total Fund: ${data["totalFund"] ?? 0}"),
                      Text("Annual Fund Paid: ${data["annualFundPaid"] ?? 0}"),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}