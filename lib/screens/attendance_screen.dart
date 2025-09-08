import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  final String matchId;
  const AttendanceScreen({super.key, required this.matchId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> playersData = []; // name, fee, attendance
  TextEditingController nameController = TextEditingController();
  TextEditingController feeController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    feeController.dispose();
    super.dispose();
  }

  Future<void> _loadHBSTeamPlayers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("matches")
          .doc(widget.matchId)
          .collection("players")
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("⚠️ No players found for match ${widget.matchId}");
      }

      setState(() {
        playersData = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            "id": doc.id,
            "name": data["Batsman"] ?? "Unknown",
            "fee": 0,
            "attendance": false,
            "date": DateTime.now(),
          };
        }).toList();
      });

      debugPrint("✅ Loaded players: $playersData");
    } catch (e) {
      debugPrint("❌ Failed to load match players: $e");
    }
  }


  // Save attendance to Firebase
  Future<void> saveAttendance() async {
    final batch = FirebaseFirestore.instance.batch();
    final matchRef = FirebaseFirestore.instance.collection("matches").doc(widget.matchId);

    for (final player in playersData) {
      final playerId = player["id"] ?? player["name"]; // Prefer a stable UID
      final attRef = matchRef.collection("attendance").doc(playerId);

      batch.set(attRef, {
        "name": player["name"],
        "attendance": player["attendance"],
        "matchFee": player["fee"],
        "matchFeePaid": false, // keep it independent
        "date": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Sheet"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Manual Add Player
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameController,
                    decoration:  InputDecoration(
                      labelText: "Player Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Fee",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        feeController.text.trim().isEmpty) return;

                    setState(() {
                      playersData.add({
                        "name": nameController.text.trim(),
                        "fee": int.tryParse(feeController.text.trim()) ?? 0,
                        "attendance": true,
                        "date": DateTime.now(),
                      });
                      nameController.clear();
                      feeController.clear();
                    });
                  },
                  child:  Text("Add"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Attendance List Table
          Expanded(
            child: ListView.builder(
              itemCount: playersData.length,
              itemBuilder: (context, index) {
                final player = playersData[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(flex: 3, child: Text(player["name"])),
                        Expanded(flex: 2, child: Text("${player["fee"]}")),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              const Text("Present"),
                              Switch(
                                value: player["attendance"],
                                onChanged: (val) {
                                  setState(() {
                                    player["attendance"] = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "${player["date"].day}-${player["date"].month}-${player["date"].year}",
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          playersData.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        icon: const Icon(Icons.save),
        label: const Text("Save Attendance"),
        onPressed: () async {
          await saveAttendance();
          Navigator.pop(context);
        },
      ),
    );
  }
}
