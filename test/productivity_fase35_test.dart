import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/models/productivity_ops_models.dart';

void main() {
  group('AfterProdEngine', () {
    test('excludes GL/TL, prioritizes Vokasi jobs, and places leftover TMs in Standby', () {
      const members = [
        AfterProdMember(id: 1, name: 'GL Budi', role: 'GL', statusKaryawan: 'Tetap'),
        AfterProdMember(id: 2, name: 'TL Andi', role: 'TL', statusKaryawan: 'Tetap'),
        AfterProdMember(id: 3, name: 'TM Vokasi 1', role: 'TM', statusKaryawan: 'Vokasi', line: 'Pos 1'),
        AfterProdMember(id: 4, name: 'TM Tetap 1', role: 'TM', statusKaryawan: 'Tetap', line: 'Pos 2'),
        AfterProdMember(id: 5, name: 'TM Kontrak 1', role: 'TM', statusKaryawan: 'Kontrak', line: 'Pos 3'),
        AfterProdMember(id: 6, name: 'TM Absent', role: 'TM', statusKaryawan: 'Tetap', present: false),
      ];

      const jobs = [
        AfterProdJob(id: 10, name: 'Sapu Area', requiredPeople: 1, allowedStatuses: ['Tetap']),
        AfterProdJob(id: 11, name: '5S Papan KPI', requiredPeople: 1, allowedStatuses: ['Vokasi']),
        AfterProdJob(id: 12, name: 'Butuh Banyak', requiredPeople: 3, allowedStatuses: ['Tetap', 'Kontrak']),
      ];

      final res = AfterProdEngine.generateAssignments(
        members: members,
        jobs: jobs,
        shift: 'RED',
        seed: 42,
      );

      final vokasiJob = res.firstWhere((a) => a.jobId == 11);
      expect(vokasiJob.status, 'Terisi');
      expect(vokasiJob.members, ['TM Vokasi 1']);

      final tetapJob = res.firstWhere((a) => a.jobId == 10);
      expect(tetapJob.status, 'Terisi');
      expect(tetapJob.members, ['TM Tetap 1']);

      final offJob = res.firstWhere((a) => a.jobId == 12);
      expect(offJob.status, 'Off (Kekurangan MP)');
      expect(offJob.members, isEmpty);

      final standby = res.firstWhere((a) => a.jobId == -1);
      expect(standby.status, 'Sisa MP');
      expect(standby.members, ['TM Kontrak 1']);
    });

    test('buildWhatsappText formats assignments cleanly', () {
      const list = [
        AfterProdAssignment(
          jobId: 1,
          jobName: 'Sapu Pos 1',
          emoji: '🧹',
          requiredPeople: 2,
          members: ['Asep', 'Budi'],
          status: 'Terisi',
        ),
        AfterProdAssignment(
          jobId: 2,
          jobName: 'Lap Jig',
          emoji: '🔧',
          requiredPeople: 2,
          members: [],
          status: 'Off (Kekurangan MP)',
        ),
      ];
      final txt = AfterProdEngine.buildWhatsappText(
        date: '2026-11-26',
        shift: 'RED',
        jamPulang: '18.15',
        assignments: list,
      );
      expect(txt, contains('TUGAS AFTER PRODUKSI 5S'));
      expect(txt, contains('18.15 WIB'));
      expect(txt, contains('Asep, Budi'));
      expect(txt, contains('_Off (Kekurangan MP)_'));
    });
  });

  group('TaskHubEngine', () {
    test('schedules In Progress at day 0 and pending by Urgent -> High -> Medium -> Low', () {
      const tasks = [
        TaskHubItem(id: 1, title: 'Low Task', moduleName: 'M', status: 'To Do', priority: 'Low', assignee: 'A', estimasiHari: 2),
        TaskHubItem(id: 2, title: 'Active Task', moduleName: 'M', status: 'In Progress', priority: 'Medium', assignee: 'B', estimasiHari: 3),
        TaskHubItem(id: 3, title: 'Urgent Task', moduleName: 'M', status: 'To Do', priority: 'Urgent', assignee: 'C', estimasiHari: 2),
        TaskHubItem(id: 4, title: 'Done Task', moduleName: 'M', status: 'Done', priority: 'High', assignee: 'D', estimasiHari: 1),
      ];

      final sched = TaskHubEngine.buildUrgencyTimeline(tasks);
      expect(sched.slots.first.task.id, 2);
      expect(sched.slots.first.startOffset, 0);
      expect(sched.slots.first.endDay, 3);

      // Urgent comes right after In Progress (offset 3..5)
      expect(sched.slots[1].task.id, 3);
      expect(sched.slots[1].startOffset, 3);
      expect(sched.slots[1].endDay, 5);

      // Low comes after Urgent (offset 5..7)
      expect(sched.slots[2].task.id, 1);
      expect(sched.slots[2].startOffset, 5);
      expect(sched.slots[2].endDay, 7);

      expect(sched.totalDays, 14);
    });
  });

  group('ShiftTemplateMath', () {
    test('computes dynamic plan regular, full OT, and total hours', () {
      const slots = [
        ShiftTemplateSlot(slotNo: 1, startTime: '07:15', endTime: '08:15', durationMin: 60),
        ShiftTemplateSlot(slotNo: 2, startTime: '08:15', endTime: '09:15', durationMin: 60),
        ShiftTemplateSlot(slotNo: 3, startTime: '16:15', endTime: '17:15', durationMin: 60, isOvertime: true),
        ShiftTemplateSlot(slotNo: 4, startTime: '17:15', endTime: '18:15', durationMin: 60, isOvertime: true, isActive: false),
      ];

      final sum = ShiftTemplateMath.computeSummary(slots, 2.4);
      // 60 / 2.4 = 25 units per active slot
      expect(sum.planRegular, 50);
      expect(sum.planFullOt, 75);
      expect(sum.totalHours, 3.0);
      expect(sum.activeSlots, 3);
    });
  });

  group('ProdKaizenItem', () {
    test('serializes and deserializes cleanly', () {
      const item = ProdKaizenItem(
        id: 'kz_99',
        tag: 'CHOKOTEI',
        month: '2026-11',
        theme: 'Cover Sensor Clamp',
        lineProcess: 'Robot 202',
        pic: 'TL Red',
        beforeValue: '15 mnt',
        afterValue: '0 mnt',
        status: 'SUDAH',
        rootCause: 'Spatter',
        countermeasure: 'Bracket Tembaga',
      );
      final parsed = ProdKaizenItem.fromJson(item.toJson());
      expect(parsed.id, 'kz_99');
      expect(parsed.theme, 'Cover Sensor Clamp');
      expect(parsed.status, 'SUDAH');
      expect(parsed.afterValue, '0 mnt');
    });
  });
}
