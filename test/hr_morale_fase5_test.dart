import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/models/hr_morale_models.dart';

void main() {
  group('BacaDoaEngine', () {
    test('skips Monday (Briefing Masal) and Weekend in Tue-Fri rotation', () {
      const ops = [
        BacaDoaOperator(id: 1, name: 'Op A'),
        BacaDoaOperator(id: 2, name: 'Op B'),
      ];
      final res = BacaDoaEngine.generateTueToFriRotation(ym: '2026-11', operators: ops);

      // Nov 2026: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
      expect(res.containsKey(1), isFalse); // Sunday
      expect(res.containsKey(2), isFalse); // Monday (Briefing Masal)
      expect(res[3]?.memberName, 'Op A');
      expect(res[4]?.memberName, 'Op B');
      expect(res[5]?.memberName, 'Op A');
      expect(res[6]?.memberName, 'Op B');
      expect(res.containsKey(7), isFalse); // Saturday
    });
  });

  group('RankMpEngine', () {
    test('computes points, multi-duty bonus, tier, and sorts descending', () {
      const ops = [
        BacaDoaOperator(id: 1, name: 'Budi', noreg: '001'),
        BacaDoaOperator(id: 2, name: 'Asep', noreg: '002'),
      ];
      const records = {
        3: BacaDoaAssignment(day: 3, memberId: 1, memberName: 'Budi', status: 'done'),
        5: BacaDoaAssignment(day: 5, memberId: 1, memberName: 'Budi', status: 'done'),
        4: BacaDoaAssignment(day: 4, memberId: 2, memberName: 'Asep', status: 'scheduled'),
      };
      const evals = {
        1: RankMpCustomEval(customPoints: 5, notes: 'Bagus'),
      };

      final ranked = RankMpEngine.computeRankings(
        shift: 'RED',
        operators: ops,
        bacaDoaRecords: records,
        customEvals: evals,
      );

      // Budi: 2*15 (doa) + 15 (multi-duty) + 10 (disiplin) + 5 (custom) = 60 -> Tier S
      expect(ranked.first.name, 'Budi');
      expect(ranked.first.totalPoints, 60);
      expect(ranked.first.tier, 'S');
      expect(ranked.first.isMultiDuty, isTrue);

      // Asep: 0 (done) + 5 (scheduled) + 0 (multi) + 10 (disiplin) = 15 -> Tier C
      expect(ranked.last.name, 'Asep');
      expect(ranked.last.totalPoints, 15);
      expect(ranked.last.tier, 'C');
    });
  });

  group('HrIdeaMath', () {
    test('calculates Idea/MP and Participant % from daily entries or manual fallback', () {
      final dailyIdea = List<int?>.filled(31, null);
      final dailyMaker = List<int?>.filled(31, null);
      dailyIdea[0] = 20;
      dailyIdea[1] = 20;
      dailyMaker[0] = 10;
      dailyMaker[1] = 10;

      final team = HrIdeaTeamData(mp: 20, dailyIdea: dailyIdea, dailyMaker: dailyMaker);
      final m = HrIdeaMath.computeTeamMetrics(team, 30);
      expect(m.totalIdea, 40);
      expect(m.totalMaker, 20);
      expect(m.ideaPerMp, 2.0);
      expect(m.partPct, 100.0);

      // Manual fallback when daily is empty
      final emptyTeam = HrIdeaTeamData.empty(mp: 10).copyWith(totalIdeaManual: 15, totalMakerManual: 8);
      final m2 = HrIdeaMath.computeTeamMetrics(emptyTeam, 30);
      expect(m2.totalIdea, 15);
      expect(m2.ideaPerMp, 1.5);
      expect(m2.partPct, 80.0);
    });
  });
}
