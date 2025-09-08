import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PublicViewScreen extends StatelessWidget {
  const PublicViewScreen({super.key});

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double _toDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  Widget _buildPlayerRow(Map<String, dynamic>? batsman, Map<String, dynamic>? bowler) {
    batsman ??= {};
    bowler ??= {};

    final overs = _toInt(bowler['Balls'] ?? 0) ~/ 6;
    final balls = _toInt(bowler['Balls'] ?? 0) % 6;

    final batsmanColor = (batsman['outstatus'] == 'out')
        ? Colors.grey.shade300
        : (_toDouble(batsman['strikerate']) > 100)
        ? Colors.green.shade200
        : Colors.blue.shade100;

    final bowlerColor = Colors.red.shade200;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade100]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bowler
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bowlerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bowler", style: TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(
                    "${bowler['Bowler'] ?? ''}\nO:$overs.$balls  R:${_toInt(bowler['runs'])}  W:${_toInt(bowler['wickets'])}\nEcon:${_toDouble(bowler['economy']).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Batsman
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: batsmanColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Batsman", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(
                    "${batsman['Batsman'] ?? ''} (${batsman['outstatus'] ?? 'notout'})\nR:${_toInt(batsman['runs'])}  B:${_toInt(batsman['balls'])}\n4s:${_toInt(batsman['fours'])}  6s:${_toInt(batsman['sixes'])}  SR:${_toDouble(batsman['strikerate']).toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Last 6 balls UI
  Widget _buildLast6Balls(String matchId, String inningDoc) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('innings')
          .doc(inningDoc)
          .collection('balls')
          .orderBy('timestamp', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final balls = snap.data!.docs;
        if (balls.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.only(top: 6),
          child: Row(
            children: balls.map((b) {
              final d = b.data() as Map<String, dynamic>;
              final isW = (d['isWicket'] == true);
              final isX = (d['isExtra'] == true);
              final bgColor = isW
                  ? Colors.red.shade700
                  : isX
                  ? Colors.orange.shade600
                  : Colors.green.shade600;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bgColor.withOpacity(0.7), bgColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (d['summary'] ?? '').toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Inning Players Layout
  Widget _buildInningPlayers(String matchId, String inningDoc) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('innings')
          .doc(inningDoc)
          .collection('players')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapPlayers) {
        if (!snapPlayers.hasData) return const SizedBox();
        final players = snapPlayers.data!.docs.map((e) => e.data() as Map<String, dynamic>).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .doc(matchId)
              .collection('innings')
              .doc(inningDoc)
              .collection('bowlers')
              .orderBy('createdAt')
              .snapshots(),
          builder: (context, snapBowlers) {
            if (!snapBowlers.hasData) return const SizedBox();
            final bowlers = snapBowlers.data!.docs.map((e) => e.data() as Map<String, dynamic>).toList();

            final maxLen = players.length > bowlers.length ? players.length : bowlers.length;

            return Column(
              children: List.generate(maxLen, (i) {
                final batsman = i < players.length ? players[i] : null;
                final bowler = i < bowlers.length ? bowlers[i] : null;
                return _buildPlayerRow(batsman, bowler);
              }),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("🏏 HBS Live Scores"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final matches = snapshot.data!.docs;
          if (matches.isEmpty) return const Center(child: Text("No matches available."));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final matchData = match.data() as Map<String, dynamic>? ?? {};

              final teamA = matchData['teamA'] ?? '';
              final teamB = matchData['teamB'] ?? '';
              final toss = matchData['toss'] ?? 'Toss Pending';
              final battingTeam = matchData['battingTeam'] ?? '';
              final bowlingTeam = matchData['bowlingTeam'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$teamA 🆚 $teamB", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 6),
                      Text("🎲 Toss: $toss", style: const TextStyle(color: Colors.black54)),
                      Text("Batting: $battingTeam | Bowling: $bowlingTeam",
                          style: const TextStyle(color: Colors.black54)),
                      const Divider(height: 20, thickness: 1),

                      //  Inning 1
                      const Text("1️⃣ First Inning", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('matches')
                            .doc(match.id)
                            .collection('innings')
                            .doc('1')
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox();
                          final inning1 = snap.data?.data() as Map<String, dynamic>? ?? {};
                          final runs1 = _toInt(inning1['runs']);
                          final wickets1 = _toInt(inning1['wickets']);
                          final overs1 = _toInt(inning1['overs']);
                          final balls1 = _toInt(inning1['balls']);
                          return Text("Score: $runs1/$wickets1  Overs: $overs1.$balls1",
                              style: const TextStyle(fontWeight: FontWeight.bold));
                        },
                      ),
                      _buildInningPlayers(match.id, '1'),
                      _buildLast6Balls(match.id, '1'),

                      const SizedBox(height: 12),

                      // Inning 2
                      const Text("2️⃣ Second Inning", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('matches')
                            .doc(match.id)
                            .collection('innings')
                            .doc('2')
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox();
                          final inning2 = snap.data?.data() as Map<String, dynamic>? ?? {};
                          if (inning2.isEmpty) return const SizedBox();
                          final runs2 = _toInt(inning2['runs']);
                          final wickets2 = _toInt(inning2['wickets']);
                          final overs2 = _toInt(inning2['overs']);
                          final balls2 = _toInt(inning2['balls']);
                          return Text("Score: $runs2/$wickets2  Overs: $overs2.$balls2",
                              style: const TextStyle(fontWeight: FontWeight.bold));
                        },
                      ),
                      _buildInningPlayers(match.id, '2'),
                      _buildLast6Balls(match.id, '2'),

                      //  Winner Box
                      if ((matchData['matchResult'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              matchData['matchResult'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
