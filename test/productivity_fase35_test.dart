import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/models/productivity_ops_models.dart';

void main() {
  group('AfterProdEngine', () {
    test('excludes GL/TL by role and known leader names, prioritizes Vokasi jobs, and places leftover TMs in Standby', () {
      const members = [
        AfterProdMember(id: 1, name: 'GL Budi', role: 'GL', statusKaryawan: 'Tetap'),
        AfterProdMember(id: 2, name: 'TL Andi', role: 'TL', statusKaryawan: 'Tetap'),
        AfterProdMember(id: 14, name: 'NUNU FATULAH', role: 'TM', statusKaryawan: 'Tetap'),
        AfterProdMember(id: 12, name: 'DWI MULYONO', role: 'TM', statusKaryawan: 'Tetap'),
        AfterProdMember(id: 3, name: 'TM Vokasi 1', role: 'TM', statusKaryawan: 'Vokasi', line: 'Pos 1'),
        AfterProdMember(id: 4, name: 'TM Tetap 1', role: 'TM', statusKaryawan: 'Tetap', line: 'Pos 2'),
        AfterProdMember(id: 5, name: 'TM Kontrak 1', role: 'TM', statusKaryawan: 'Kontrak', line: 'Pos 3'),
        AfterProdMember(id: 6, name: 'TM Absent', role: 'TM', statusKaryawan: 'Tetap', present: false),
      ];

      expect(members[2].isEligibleFor5S, isFalse);
      expect(members[3].isEligibleFor5S, isFalse);

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

      final allAssigned = res.expand((r) => r.members).toList();
      expect(allAssigned, isNot(contains('NUNU FATULAH')));
      expect(allAssigned, isNot(contains('DWI MULYONO')));

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

    test('parses Next.js Atlas job payload and auto-assigns 1:1 emoji', () {
      final j1 = AfterProdJob.fromJson({
        'id': 101,
        'job_name': '5R Rest Area ALL + Renew Stiker Kaki',
        'shift': 'COMMON',
        'required_people': 1,
        'allowed_status': '',
        'is_active': true,
      });
      final j2 = AfterProdJob.fromJson({
        'id': 102,
        'job_name': '5R Jalur Tamu + Renew Stiker',
        'shift': 'WHITE',
        'required_people': 1,
        'allowed_status': 'vokasi',
        'is_active': 1,
      });
      final j3 = AfterProdJob.fromJson({
        'id': 103,
        'job_name': '5R Buang Sampah',
        'shift': 'RED',
        'required_people': 2,
        'is_active': 1,
      });

      expect(j1.scope, 'COMMON');
      expect(j1.emoji, '🌳');
      expect(j1.allowedStatuses.length, 3);
      expect(j2.scope, 'WHITE');
      expect(j2.emoji, '🤝');
      expect(j2.allowedStatuses, ['Vokasi']);
      expect(j3.emoji, '🗑️');
    });

    test('moveMember and swapMembers update assignments cleanly', () {
      const initial = [
        AfterProdAssignment(
          jobId: 1,
          jobName: '5R Rest Area',
          emoji: '🌳',
          requiredPeople: 1,
          members: ['WISNU'],
          status: 'Terisi',
        ),
        AfterProdAssignment(
          jobId: 2,
          jobName: '5R Jalur Tamu',
          emoji: '🤝',
          requiredPeople: 1,
          members: ['RISKI'],
          status: 'Terisi',
        ),
      ];

      // Swap WISNU <-> RISKI
      final swapped = AfterProdEngine.swapMembers(
        assignments: initial,
        aJobIdx: 0,
        aMemberIdx: 0,
        bJobIdx: 1,
        bMemberIdx: 0,
      );
      expect(swapped[0].members, ['RISKI']);
      expect(swapped[1].members, ['WISNU']);

      // Move RISKI from job 0 to job 1
      final moved = AfterProdEngine.moveMember(
        assignments: swapped,
        fromJobIdx: 0,
        memberName: 'RISKI',
        toJobIdx: 1,
      );
      expect(moved[0].members, isEmpty);
      expect(moved[0].status, 'Off (Kekurangan MP)');
      expect(moved[1].members, ['WISNU', 'RISKI']);
      expect(moved[1].status, 'Terisi');
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
