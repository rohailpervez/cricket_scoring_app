import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cricket_scoring_app/finalyear_budget/player_profile_screen.dart';
import 'package:flutter/material.dart';

class PlayersListScreen extends StatelessWidget {
  const PlayersListScreen({super.key});

  Future<void> _deletePlayer(BuildContext context, String playerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Player"),
        content: const Text("⚠️ Are you sure you want to delete this player?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection("career").doc(playerId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Player deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("All Players"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("career").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data!.docs;

          if (players.isEmpty) {
            return const Center(child: Text("No players found"));
          }

          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final data = players[index].data() as Map<String, dynamic>;
              final playerId = players[index].id;

              return Card(
                margin:  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (data["imageUrl"] != null && data["imageUrl"] != "")
                        ? NetworkImage(data["imageUrl"])
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: (data["imageUrl"] == null || data["imageUrl"] == "")
                        ?  Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    data["name"] ?? playerId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Role: ${data["role"] ?? "-"}"),
                      const SizedBox(height: 5),
                      Text("🏏 Runs: ${data["totalRuns"] ?? 0} | 50s: ${data["fifties"] ?? 0} | 100s: ${data["hundered"] ?? 0}"),
                      Text("🎯 Wickets: ${data["wickets"] ?? 0} | Overs: ${data["overs"] ?? 0} | Econ: ${(data["economy"] ?? 0).toStringAsFixed(2)}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePlayer(context, playerId),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 18),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerProfileScreen(playerId: playerId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}