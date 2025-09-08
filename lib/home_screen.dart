import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cricket_scoring_app/finalyear_budget/players_list_screen.dart';
import 'package:cricket_scoring_app/screens/match_detail_screen.dart';
import 'package:cricket_scoring_app/screens/public_view_screen.dart';
import 'package:cricket_scoring_app/screens/attendance_screen.dart'; // 👈 Attendance wali screen import karo
import 'package:cricket_scoring_app/screens/save_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'finalyear_budget/final_year_Budget_Screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Center(child: Text("HBS Tiger Scoring")),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PublicViewScreen(),
                ),
              );
            },
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text(
              "Public View",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      // Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context); // Drawer band
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Attendance Sheet"),
              onTap: () {
                Navigator.pop(context); // Drawer close

                FirebaseFirestore.instance
                    .collection('matches')
                    .orderBy('createdAt', descending: true)
                    .limit(1)
                    .get()
                    .then((snapshot) {
                  if (snapshot.docs.isNotEmpty) {
                    String matchId = snapshot.docs.first.id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceScreen(matchId: matchId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No match available for attendance")),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text("Saved Attendance"),
              onTap: () {
                Navigator.pop(context); // Drawer band
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedAttendanceScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading:  Icon(Icons.attach_money),
              title:  Text("Final Year Budget"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  FinalYearBudgetScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Player Profiles"),
              onTap: () {
                Navigator.pop(context); // Drawer close
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  PlayersListScreen(),
                  ),
                );
              },
            ),


          ],
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFE0E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final matches = snapshot.data!.docs;

            if (matches.isEmpty) {
              return const Center(
                child: Text(
                  "No matches available.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 80),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final matchData = match.data() as Map<String, dynamic>? ?? {};

                final teamA = matchData['teamA'] ?? '';
                final teamB = matchData['teamB'] ?? '';
                final toss = matchData['toss'] ?? 'Toss Pending';
                final battingTeam = matchData['battingTeam'] ?? '';
                final bowlingTeam = matchData['bowlingTeam'] ?? '';
                final status = matchData['status'] ?? 'upcoming';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      "$teamA 🆚 $teamB",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text("Toss Winner: $toss"),
                        Text("Batting: $battingTeam  |  Bowling: $bowlingTeam"),
                        const SizedBox(height: 6),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('matches')
                              .doc(match.id)
                              .collection('innings')
                              .doc('1')
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox();
                            final inning1 =
                                snap.data?.data() as Map<String, dynamic>? ??
                                    {};
                            final runs1 = inning1['runs'] ?? 0;
                            final wickets1 = inning1['wickets'] ?? 0;
                            final overs1 = inning1['overs'] ?? 0;
                            final balls1 = inning1['balls'] ?? 0;

                            String oversText1 = "$overs1.$balls1";

                            return Text(
                              "1st Inning: $runs1/$wickets1  Overs: $oversText1",
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('matches')
                              .doc(match.id)
                              .collection('innings')
                              .doc('2')
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox();
                            final inning2 =
                                snap.data?.data() as Map<String, dynamic>? ??
                                    {};
                            if (inning2.isEmpty) return const SizedBox();
                            final runs2 = inning2['runs'] ?? 0;
                            final wickets2 = inning2['wickets'] ?? 0;
                            final overs2 = inning2['overs'] ?? 0;
                            final balls2 = inning2['balls'] ?? 0;

                            String oversText2 = "$overs2.$balls2";

                            return Text(
                              "2nd Inning: $runs2/$wickets2  Overs: $oversText2",
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_cricket,
                          color: status == 'live' ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Delete Match"),
                                content: const Text(
                                    "Are you sure you want to delete this match?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('matches')
                                  .doc(match.id)
                                  .delete();
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MatchDetailScreen(matchId: match.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.red, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            final teamAController = TextEditingController();
            final teamBController = TextEditingController();
            String tossWinner = '';
            String tossDecision = 'Batting';

            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text("Start New Match"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: teamAController,
                            decoration:
                            const InputDecoration(labelText: "Team A"),
                          ),
                          TextField(
                            controller: teamBController,
                            decoration:
                            const InputDecoration(labelText: "Team B"),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: tossWinner.isEmpty ? null : tossWinner,
                            hint: const Text("Select Toss Winner"),
                            items: const [
                              DropdownMenuItem(
                                  value: 'TeamA', child: Text("Team A")),
                              DropdownMenuItem(
                                  value: 'TeamB', child: Text("Team B")),
                            ],
                            onChanged: (val) {
                              setState(() {
                                tossWinner = val ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          if (tossWinner.isNotEmpty)
                            DropdownButtonFormField<String>(
                              value: tossDecision,
                              items: const [
                                DropdownMenuItem(
                                    value: 'Batting', child: Text("Batting")),
                                DropdownMenuItem(
                                    value: 'Bowling', child: Text("Bowling")),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  tossDecision = val ?? 'Batting';
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          final teamA = teamAController.text.trim();
                          final teamB = teamBController.text.trim();

                          if (teamA.isNotEmpty &&
                              teamB.isNotEmpty &&
                              tossWinner.isNotEmpty) {
                            String battingTeam = '';
                            String bowlingTeam = '';

                            if (tossWinner == 'TeamA') {
                              if (tossDecision == 'Batting') {
                                battingTeam = teamA;
                                bowlingTeam = teamB;
                              } else {
                                battingTeam = teamB;
                                bowlingTeam = teamA;
                              }
                            } else {
                              if (tossDecision == 'Batting') {
                                battingTeam = teamB;
                                bowlingTeam = teamA;
                              } else {
                                battingTeam = teamA;
                                bowlingTeam = teamB;
                              }
                            }

                            FirebaseFirestore.instance
                                .collection('matches')
                                .add({
                              'teamA': teamA,
                              'teamB': teamB,
                              'toss': tossWinner == 'TeamA' ? teamA : teamB,
                              'battingTeam': battingTeam,
                              'bowlingTeam': bowlingTeam,
                              'status': 'live',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Start"),
                      ),
                    ],
                  );
                });
              },
            );
          },
        ),
      ),
    );
  }
}
