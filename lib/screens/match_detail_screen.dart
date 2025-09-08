import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int currentInning = 1;
  String selectedBatsmanId = '';
  String selectedBowlerId = '';

  DocumentReference get matchDoc => _firestore.collection('matches').doc(widget.matchId);
  DocumentReference get inningDoc => matchDoc.collection('innings').doc('$currentInning');
  CollectionReference get playersColl => inningDoc.collection('players');
  CollectionReference get bowlersColl => inningDoc.collection('bowlers');
  CollectionReference get ballsColl => inningDoc.collection('balls');

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  Future<void> _addBatsmanDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Batsman'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Player name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await playersColl.add({
                'Batsman': name,
                'runs': 0,
                'balls': 0,
                'fours': 0,
                'sixes': 0,
                'outstatus': 'notout',
                'strikerate': 0.0,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBowlerDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Bowler'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Bowler name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await bowlersColl.add({
                'Bowler': name,
                'runs': 0,
                'Balls': 0,
                'wickets': 0,
                'wides': 0,
                'noballs': 0,
                'overs': 0,
                'maidens': 0,
                'economy': 0.0,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBall(String batsmanId, String bowlerId, String action) async {
    if (batsmanId.isEmpty || bowlerId.isEmpty) return;

    final batsmanDoc = playersColl.doc(batsmanId);
    final bowlerDoc = bowlersColl.doc(bowlerId);
    final batsmanSnap = await batsmanDoc.get();
    final bowlerSnap = await bowlerDoc.get();
    if (!batsmanSnap.exists || !bowlerSnap.exists) return;

    final batsman = (batsmanSnap.data() as Map<String, dynamic>?) ?? {};
    final bowler = (bowlerSnap.data() as Map<String, dynamic>?) ?? {};

    int runs = _toInt(batsman['runs']);
    int balls = _toInt(batsman['balls']);
    int fours = _toInt(batsman['fours']);
    int sixes = _toInt(batsman['sixes']);
    String outStatus = (batsman['outstatus'] ?? 'notout');

    int bRuns = _toInt(bowler['runs']);
    int bBalls = _toInt(bowler['Balls']);
    int wickets = _toInt(bowler['wickets']);
    int wides = _toInt(bowler['wides']);
    int noballs = _toInt(bowler['noballs']);

    final matchSnap = await inningDoc.get();
    final matchData = (matchSnap.data() as Map<String, dynamic>?) ?? {};
    int totalRuns = _toInt(matchData['runs']);
    int totalWickets = _toInt(matchData['wickets']);
    int overNum = _toInt(matchData['overs']);
    int overBalls = _toInt(matchData['balls']);

    int thisBallBatterRuns = 0;
    int thisBallExtras = 0;
    bool legalBall = true;
    bool isWicket = false;
    String summary = '';

    switch (action) {
      case '1':
      case '2':
      case '3':
      case '4':
      case '6':
        final r = int.parse(action);
        runs += r;
        balls += 1;
        thisBallBatterRuns += r;
        if (r == 4) fours++;
        if (r == 6) sixes++;
        summary = '$r';
        break;
      case 'dot':
        balls += 1;
        summary = '•';
        break;
      case 'out':
        balls += 1;
        isWicket = true;
        outStatus = 'out';
        summary = 'W';
        break;
      case 'wide':
        wides += 1;
        thisBallExtras += 1;
        legalBall = false;
        summary = 'Wd';
        break;
      case 'noball':
        noballs += 1;
        thisBallExtras += 1;
        legalBall = false;
        summary = 'Nb';
        break;
    }

    final thisBallBowlerRuns = thisBallBatterRuns + thisBallExtras;
    totalRuns += thisBallBowlerRuns;
    if (isWicket) totalWickets += 1;

    final newBBalls = bBalls + (legalBall ? 1 : 0);
    final newBRuns = bRuns + thisBallBowlerRuns;
    final newBWkts = wickets + (isWicket ? 1 : 0);

    if (legalBall) {
      overBalls += 1;
      if (overBalls >= 6) {
        overNum += 1;
        overBalls = 0;
      }
    }

    await batsmanDoc.update({
      'runs': runs,
      'balls': balls,
      'fours': fours,
      'sixes': sixes,
      'outstatus': outStatus,
      'strikerate': balls > 0 ? double.parse(((runs / balls) * 100).toStringAsFixed(2)) : 0.0,
    });

    await bowlerDoc.update({
      'runs': newBRuns,
      'Balls': newBBalls,
      'wickets': newBWkts,
      'wides': wides,
      'noballs': noballs,
      'economy': newBBalls > 0 ? double.parse((newBRuns / (newBBalls / 6)).toStringAsFixed(2)) : 0.0,
      'overs': newBBalls ~/ 6,
    });

    await inningDoc.set({
      'runs': totalRuns,
      'wickets': totalWickets,
      'overs': overNum,
      'balls': overBalls,
    }, SetOptions(merge: true));

    await ballsColl.add({
      'over': '$overNum.$overBalls',
      'batsman': (batsman['Batsman'] ?? '').toString(),
      'bowler': (bowler['Bowler'] ?? '').toString(),
      'summary': summary,
      'runs': thisBallBowlerRuns,
      'isWicket': isWicket,
      'isExtra': action == 'wide' || action == 'noball',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateCareerStatsAtMatchEnd() async {
    final inningsSnap = await matchDoc.collection("innings").get();

    final Set<String> playersCounted = {};

    for (var inningDoc in inningsSnap.docs) {
      // 🏏 Batsmen
      final batsmenSnap = await inningDoc.reference.collection("players").get();
      for (var batsman in batsmenSnap.docs) {
        final d = batsman.data();
        final playerName = d['Batsman'].toString();

        final runs = d['runs'] ?? 0;
        final fifties = runs >= 50 && runs < 100 ? 1 : 0;
        final hundreds = runs >= 100 ? 1 : 0;

        final playerRef = FirebaseFirestore.instance
            .collection("career")
            .doc(playerName);

        await FirebaseFirestore.instance.runTransaction((t) async {
          final snap = await t.get(playerRef);

          Map<String, dynamic> old = {};
          if (!snap.exists) {

            old = {
              "name": playerName,
              "matchesPlayed": 0,
              "totalRuns": 0,
              "highestScore": 0,
              "fifties": 0,
              "hundered": 0,
              "average": 0.0,
              "wickets": 0,
              "overs": 0,
              "runConceeded": 0,
              "bestFigure": "0/0",
              "economy": 0.0,
              "role": "Unknown",
              "phone": 0,
              "imageUrl": "",
              "annualFundPaid": 0,
              "totalFund": 0,
            };
            t.set(playerRef, old);
          } else {
            old = snap.data() as Map<String, dynamic>;
          }


          final newRuns = (old['totalRuns'] ?? 0) + runs;
          final oldHS = (old['highestScore'] ?? 0);
          final updatedHS = runs > oldHS ? runs : oldHS;


          final newMatches = (old['matchesPlayed'] ?? 0) +
              (playersCounted.contains(playerName) ? 0 : 1);
          playersCounted.add(playerName);

          t.update(playerRef, {
            "matchesPlayed": newMatches,
            "totalRuns": newRuns,
            "highestScore": updatedHS,
            "fifties": (old['fifties'] ?? 0) + fifties,
            "hundered": (old['hundered'] ?? 0) + hundreds,
            "average": newMatches > 0 ? (newRuns / newMatches) : 0.0,
          });
        });
      }


      // 🎯 Bowlers
      final bowlersSnap = await inningDoc.reference.collection("bowlers").get();
      for (var bowler in bowlersSnap.docs) {
        final d = bowler.data();
        final playerName = d['Bowler'].toString();

        final wickets = d['wickets'] ?? 0;
        final runsConceded = d['runs'] ?? 0;
        final overs = (d['Balls'] ?? 0) ~/ 6;

        final bestFigureThisMatch = "${wickets}/${runsConceded}";

        final playerRef = FirebaseFirestore.instance
            .collection("career")
            .doc(playerName);

        await FirebaseFirestore.instance.runTransaction((t) async {
          final snap = await t.get(playerRef);

          Map<String, dynamic> old = {};
          if (!snap.exists) {

            old = {
              "name": playerName,
              "matchesPlayed": 0,
              "totalRuns": 0,
              "highestScore": 0,
              "fifties": 0,
              "hundered": 0,
              "average": 0.0,
              "wickets": 0,
              "overs": 0,
              "runConceeded": 0,
              "bestFigure": "0/0",
              "economy": 0.0,
              "role": "Unknown",
              "phone": 0,
              "imageUrl": "",
              "annualFundPaid": 0,
              "totalFund": 0,
            };
            t.set(playerRef, old); // create with defaults
          } else {
            old = snap.data() as Map<String, dynamic>;
          }

          final oldBest = (old['bestFigure'] ?? "0/0").toString();
          final oldW = int.tryParse(oldBest.split("/")[0]) ?? 0;
          final oldR = int.tryParse(oldBest.split("/")[1]) ?? 9999;

          String newBest = oldBest;
          if (wickets > oldW || (wickets == oldW && runsConceded < oldR)) {
            newBest = bestFigureThisMatch;
          }

          final totalOvers = (old['overs'] ?? 0) + overs;
          final totalRunsConceded = (old['runConceeded'] ?? 0) + runsConceded;
          final totalWickets = (old['wickets'] ?? 0) + wickets;
          final newMatches = (old['matchesPlayed'] ?? 0) +
              (playersCounted.contains(playerName) ? 0 : 1);
          playersCounted.add(playerName);


          t.update(playerRef, {
            "matchesPlayed": newMatches,
            "overs": totalOvers,
            "runConceeded": totalRunsConceded,
            "wickets": totalWickets,
            "bestFigure": newBest,
            "economy": totalOvers > 0 ? totalRunsConceded / totalOvers : 0.0,
          });
        });
      }

    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          "Match - Inning $currentInning",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
              tooltip: "Switch Inning",
              onPressed: () {
                setState(() {
                  currentInning = currentInning == 1 ? 2 : 1;
                  selectedBatsmanId = '';
                  selectedBowlerId = '';
                });
              },
              icon: const Icon(Icons.swap_horiz, color: Colors.white)),
          IconButton(
              tooltip: "Add Batsman",
              onPressed: _addBatsmanDialog,
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white)),
          IconButton(
              tooltip: "Add Bowler",
              onPressed: _addBowlerDialog,
              icon: const Icon(Icons.sports_cricket, color: Colors.white)),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: matchDoc.snapshots(),
            builder: (context, matchSnap) {
              final matchData = (matchSnap.data?.data() as Map<String, dynamic>?) ?? {};
              final teamA = (matchData['teamA'] ?? 'Team A').toString();
              final teamB = (matchData['teamB'] ?? 'Team B').toString();
              final toss = (matchData['toss'] ?? 'Toss Pending').toString();
              final battingTeam = (matchData['battingTeam'] ?? '').toString();
              final bowlingTeam = (matchData['bowlingTeam'] ?? '').toString();

              return StreamBuilder<DocumentSnapshot>(
                stream: inningDoc.snapshots(),
                builder: (context, inningSnap) {
                  final inningData = (inningSnap.data?.data() as Map<String, dynamic>?) ?? {};
                  int totalRuns = _toInt(inningData['runs']);
                  int totalWickets = _toInt(inningData['wickets']);
                  int overNum = _toInt(inningData['overs']);
                  int overBalls = _toInt(inningData['balls']);

                  return Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.redAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(teamA,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const Text("vs",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70)),
                            Text(teamB,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        //  Toss Info
                        Text("Toss Winner: $toss",
                            style: const TextStyle(color: Colors.white70, fontSize: 14)),

                        //  Batting & Bowling Teams
                        Text("Batting: $battingTeam  |  Bowling: $bowlingTeam",
                            style: const TextStyle(color: Colors.white70, fontSize: 14)),

                        const Divider(color: Colors.white54, thickness: 1, height: 16),

                        //  Score + Overs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Inning $currentInning",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "$totalRuns/$totalWickets",
                              style: const TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Overs: $overNum.$overBalls",
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          // Players and bowlers list
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: playersColl.orderBy('createdAt').snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final players = snap.data!.docs;
                      return ListView(
                        children: players.map((p) {
                          final d = p.data() as Map<String, dynamic>;
                          return RadioListTile(
                            value: p.id,
                            groupValue: selectedBatsmanId,
                            onChanged: (val) => setState(() => selectedBatsmanId = val!),
                            title: Text("${d['Batsman']} (${d['outstatus'] ?? 'notout'})"),
                            subtitle: Text(
                                "R:${_toInt(d['runs'])}  B:${_toInt(d['balls'])}  4s:${_toInt(d['fours'])}  6s:${_toInt(d['sixes'])}  SR:${_toDouble(d['strikerate']).toStringAsFixed(2)}"),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: bowlersColl.orderBy('createdAt').snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final bowlers = snap.data!.docs;
                      return ListView(
                        children: bowlers.map((b) {
                          final d = b.data() as Map<String, dynamic>;
                          final bBalls = _toInt(d['Balls']);
                          final oversText = "${bBalls ~/ 6}.${bBalls % 6}";
                          return RadioListTile(
                            value: b.id,
                            groupValue: selectedBowlerId,
                            onChanged: (val) => setState(() => selectedBowlerId = val!),
                            title: Text("${d['Bowler']}"),
                            subtitle: Text(
                                "O:$oversText  R:${_toInt(d['runs'])}  W:${_toInt(d['wickets'])}  Econ:${_toDouble(d['economy']).toStringAsFixed(2)}  Wd:${_toInt(d['wides'])}  Nb:${_toInt(d['noballs'])}"),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Last 6 balls summary
          SizedBox(
            height: 70,
            child: StreamBuilder<QuerySnapshot>(
                stream: ballsColl.orderBy('timestamp', descending: true).limit(6).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();
                  final balls = snap.data!.docs;
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    children: balls.map((b) {
                      final d = b.data() as Map<String, dynamic>;
                      final isW = (d['isWicket'] == true);
                      final isX = (d['isExtra'] == true);
                      final bg = isW
                          ? Colors.red
                          : isX
                          ? Colors.orange
                          : Colors.green.shade600;
                      return Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
                        child: Center(
                          child: Text(
                            (d['summary'] ?? '').toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Wrap(
              spacing: 6,
              children: ['1','2','3','4','6','dot','out','wide','noball'].map((act) {
                return ElevatedButton(
                    onPressed: (selectedBatsmanId.isNotEmpty && selectedBowlerId.isNotEmpty)
                        ? () => _updateBall(selectedBatsmanId, selectedBowlerId, act)
                        : null,
                    child: Text(act.toUpperCase()));

              }).toList(),
            ),
          ),

          const SizedBox(height: 8),
          // Match Result Button (End match)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final winnerController = TextEditingController();
                  String? wonBy;
                  int? margin;

                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "🏆 Update Match Result",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: winnerController,
                            decoration: const InputDecoration(
                              labelText: "Winning Team Name",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: wonBy,
                            decoration: const InputDecoration(
                              labelText: "Won By",
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: "runs", child: Text("Runs")),
                              DropdownMenuItem(value: "wickets", child: Text("Wickets")),
                            ],
                            onChanged: (v) => wonBy = v,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Margin (Runs/Wickets)",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => margin = int.tryParse(v),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (winnerController.text.isEmpty || wonBy == null || margin == null) return;

                            // Save Match Result
                            await matchDoc.set({
                              'winner': winnerController.text.trim(),
                              'wonBy': wonBy,
                              'margin': margin,
                              'matchResult': "${winnerController.text.trim()} won by $margin $wonBy",
                            }, SetOptions(merge: true));

                            // Update Players Career Stats
                            await _updateCareerStatsAtMatchEnd();

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Match result updated & career stats updated!")),
                            );
                          },
                          child: const Text("Update"),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.flag, color: Colors.white),
                label: const Text(
                  "End Match / Set Result",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.redAccent,
                  shadowColor: Colors.black.withOpacity(0.4),
                  elevation: 6,
                ),
              ),
            ),
          )


        ],
      ),
    );
  }
}