import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/shared/models/daily_stats.dart';
import 'package:tindascan/shared/repositories/stats_repository.dart';

/// [StatsRepository] backed by `daily_stats/{yyyyMMdd}` documents.
class FirestoreStatsRepository implements StatsRepository {
  FirestoreStatsRepository(this._db);

  final FirebaseFirestore _db;

  /// Read cost: exactly one small document per day key (≤ 30 for charts),
  /// independent of how many sales happened.
  @override
  Future<List<DailyStats>> fetchDays(List<String> dayKeys) =>
      guardFailure(() async {
        final collection = _db.collection(FirestorePaths.dailyStats);
        final snaps = await Future.wait(
          dayKeys.map((key) => collection.doc(key).get()),
        );
        return [
          for (final snap in snaps)
            snap.data() == null
                ? DailyStats.empty(snap.id)
                : DailyStats.fromMap(snap.id, snap.data()!),
        ];
      });
}
