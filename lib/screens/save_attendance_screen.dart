import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SavedAttendanceScreen extends StatelessWidget {
  const SavedAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("Saved Attendance"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("matches")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data!.docs;

          if (matches.isEmpty) {
            return const Center(
              child: Text("No matches found."),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final matchId = match.id;
              final matchData = match.data() as Map<String, dynamic>? ?? {};
              final teamA = matchData['teamA'] ?? '';
              final teamB = matchData['teamB'] ?? '';
              final date = (matchData['createdAt'] as Timestamp?)?.toDate();

              return ExpansionTile(
                title: Text(
                  "$teamA 🆚 $teamB",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: date != null
                    ? Text(
                  "Date: ${date.day}-${date.month}-${date.year}",
                )
                    : null,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("matches")
                        .doc(matchId)
                        .collection("attendance")
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final attendanceDocs = snap.data!.docs;

                      if (attendanceDocs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("No attendance records found."),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: attendanceDocs.length,
                        itemBuilder: (context, i) {
                          final doc = attendanceDocs[i];
                          final data = doc.data() as Map<String, dynamic>? ?? {};
                          final name = doc.id;
                          final fee = data['matchFee'] ?? 0;
                          final attendance = data['attendance'] ?? false;
                          final date = (data['date'] as Timestamp?)?.toDate();

                          return ListTile(
                            title: Text(name),
                            subtitle: Text(
                              "Fee: $fee | Date: ${date != null ? "${date.day}-${date.month}-${date.year}" : "-"}",
                            ),
                            trailing: Text(attendance ? "Present" : "Absent"),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
