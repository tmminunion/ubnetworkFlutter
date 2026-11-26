import 'dart:math';

String ubTodayYmd() {
  final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
  return '${wib.year}-${wib.month.toString().padLeft(2, '0')}-${wib.day.toString().padLeft(2, '0')}';
}

// =============================================================================
// 1. UBAI AFTER-PROD 5S MODELS & ENGINE
// =============================================================================
class AfterProdMember {
  const AfterProdMember({
    required this.id,
    required this.name,
    this.noreg = '',
    this.role = 'TM',
    this.shift = 'RED',
    this.line = 'UB Assy',
    this.statusKaryawan = 'Tetap',
    this.present = true,
  });

  final int id;
  final String name;
  final String noreg;
  final String role;
  final String shift;
  final String line;
  final String statusKaryawan; // Tetap | Kontrak | Vokasi
  final bool present;

  /// GL & TL names that must never appear in After-Prod 5S TM list (even offline).
  static const Set<String> excludedLeaderNames = {
    'KAMALUDIN',
    'MASRURI',
    'TRI RUSTIANTORO',
    'SAIFUL RACHIM',
    'DWI MULYONO',
    'DADANG SURYADI',
    'NUNU FATULAH',
  };

  bool get isEligibleFor5S {
    final r = role.trim().toUpperCase();
    if (r == 'GL' || r == 'TL' || r.contains('LEADER')) return false;
    if (excludedLeaderNames.contains(name.trim().toUpperCase())) return false;
    return true;
  }

  static String normalizeStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.contains('vokasi') || s.contains('magang')) return 'Vokasi';
    if (s.contains('kontrak') || s.contains('pkwt')) return 'Kontrak';
    if (s.contains('tetap') || s.contains('permanen')) return 'Tetap';
    return raw.trim().isEmpty ? 'Tetap' : raw.trim();
  }

  AfterProdMember copyWith({
    int? id,
    String? name,
    String? noreg,
    String? role,
    String? shift,
    String? line,
    String? statusKaryawan,
    bool? present,
  }) {
    return AfterProdMember(
      id: id ?? this.id,
      name: name ?? this.name,
      noreg: noreg ?? this.noreg,
      role: role ?? this.role,
      shift: shift ?? this.shift,
      line: line ?? this.line,
      statusKaryawan: statusKaryawan ?? this.statusKaryawan,
      present: present ?? this.present,
    );
  }

  factory AfterProdMember.fromJson(Map<String, dynamic> j) {
    var role = '${j['role'] ?? ''}'.trim().toUpperCase();
    if (role.isEmpty) {
      final note = '${j['note'] ?? j['default_pos'] ?? ''}'.trim().toUpperCase();
      if (note.startsWith('GL')) {
        role = 'GL';
      } else if (note.startsWith('TL')) {
        role = 'TL';
      } else {
        role = 'TM';
      }
    }
    final rawPresent = j.containsKey('present') ? j['present'] : j['hadir'];
    return AfterProdMember(
      id: j['id'] is num ? (j['id'] as num).toInt() : (int.tryParse('${j['id'] ?? 0}') ?? 0),
      name: '${j['name'] ?? ''}'.trim(),
      noreg: '${j['noreg'] ?? ''}'.trim(),
      role: role,
      shift: '${j['shift'] ?? 'RED'}'.trim().toUpperCase(),
      line: '${j['default_pos'] ?? j['line_name'] ?? j['line'] ?? 'UB Assy'}'.trim(),
      statusKaryawan: normalizeStatus('${j['status_karyawan'] ?? j['status'] ?? 'Tetap'}'),
      present: rawPresent == null ? true : (rawPresent == true || rawPresent == 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'noreg': noreg,
        'role': role,
        'shift': shift,
        'line': line,
        'status_karyawan': statusKaryawan,
        'present': present,
      };
}

class AfterProdJob {
  const AfterProdJob({
    required this.id,
    required this.name,
    this.emoji = '🛠️',
    this.scope = 'COMMON',
    this.requiredPeople = 1,
    this.allowedStatuses = const ['Tetap', 'Kontrak', 'Vokasi'],
    this.preferredLine = '',
    this.isActive = true,
  });

  final int id;
  final String name;
  final String emoji;
  final String scope; // COMMON | RED | WHITE
  final int requiredPeople;
  final List<String> allowedStatuses;
  final String preferredLine;
  final bool isActive;

  bool get prioritizesVokasi =>
      allowedStatuses.any((s) => s.toLowerCase().contains('vokasi'));

  AfterProdJob copyWith({
    int? id,
    String? name,
    String? emoji,
    String? scope,
    int? requiredPeople,
    List<String>? allowedStatuses,
    String? preferredLine,
    bool? isActive,
  }) {
    return AfterProdJob(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      scope: scope ?? this.scope,
      requiredPeople: requiredPeople ?? this.requiredPeople,
      allowedStatuses: allowedStatuses ?? this.allowedStatuses,
      preferredLine: preferredLine ?? this.preferredLine,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AfterProdJob.fromJson(Map<String, dynamic> j) {
    final rawAllowed = j['allowed_status'] ?? j['allowedStatuses'];
    List<String> allowed = const ['Tetap', 'Kontrak', 'Vokasi'];
    if (rawAllowed is List) {
      final parsed = rawAllowed
          .map((e) => AfterProdMember.normalizeStatus('$e'))
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (parsed.isNotEmpty) allowed = parsed;
    } else if (rawAllowed is String && rawAllowed.trim().isNotEmpty) {
      final parsed = rawAllowed
          .split(',')
          .map((e) => AfterProdMember.normalizeStatus(e))
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (parsed.isNotEmpty) allowed = parsed;
    }
    final name = '${j['job_name'] ?? j['name'] ?? ''}'.trim();
    final rawEmoji = '${j['emoji'] ?? ''}'.trim();
    final rawScope = '${j['shift'] ?? j['scope'] ?? 'COMMON'}'.trim().toUpperCase();
    final scope = (rawScope == 'RED' || rawScope == 'WHITE') ? rawScope : 'COMMON';
    final rawActive = j['is_active'];
    return AfterProdJob(
      id: j['id'] is num ? (j['id'] as num).toInt() : (int.tryParse('${j['id'] ?? 0}') ?? 0),
      name: name,
      emoji: rawEmoji.isNotEmpty ? rawEmoji : AfterProdEngine.jobEmoji(name),
      scope: scope,
      requiredPeople: j['required_people'] is num
          ? (j['required_people'] as num).toInt()
          : (int.tryParse('${j['required_people'] ?? 1}') ?? 1),
      allowedStatuses: allowed,
      preferredLine: '${j['preferred_line'] ?? j['line'] ?? ''}'.trim(),
      isActive: rawActive == null ? true : (rawActive == true || rawActive == 1 || rawActive == '1'),
    );
  }

  Map<String, dynamic> toJson() {
    // Next.js /api/ub?action=save_after_job expects job_name, shift, line, required_people, allowed_status, is_active
    final allSelected = allowedStatuses.length >= 3;
    return {
      'id': id,
      'job_name': name,
      'name': name,
      'emoji': emoji,
      'shift': scope,
      'scope': scope,
      'required_people': requiredPeople,
      'allowed_status': allSelected ? '' : allowedStatuses.join(','),
      'line': preferredLine.isEmpty ? 'All' : preferredLine,
      'preferred_line': preferredLine,
      'is_active': isActive ? 1 : 0,
    };
  }
}

class AfterProdAssignment {
  const AfterProdAssignment({
    required this.jobId,
    required this.jobName,
    required this.emoji,
    required this.requiredPeople,
    required this.members,
    required this.status,
  });

  final int jobId;
  final String jobName;
  final String emoji;
  final int requiredPeople;
  final List<String> members;
  final String status; // Terisi | Off (Kekurangan MP) | Sisa MP

  AfterProdAssignment copyWith({
    List<String>? members,
    String? status,
  }) {
    return AfterProdAssignment(
      jobId: jobId,
      jobName: jobName,
      emoji: emoji,
      requiredPeople: requiredPeople,
      members: members ?? this.members,
      status: status ?? this.status,
    );
  }

  factory AfterProdAssignment.fromJson(Map<String, dynamic> j) {
    final rawMembers = j['petugas'] ?? j['members'];
    final members = rawMembers is List
        ? rawMembers.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final jobName = '${j['job_name'] ?? j['job'] ?? j['name'] ?? ''}'.trim();
    final rawEmoji = '${j['emoji'] ?? ''}'.trim();
    final status = '${j['status'] ?? (members.isEmpty ? 'Off (Kekurangan MP)' : 'Terisi')}'.trim();
    final isStandby = status == 'Sisa MP' ||
        jobName.toLowerCase().contains('standby') ||
        jobName.toLowerCase().contains('extra');
    final parsedId = j['job_id'] is num
        ? (j['job_id'] as num).toInt()
        : (int.tryParse('${j['job_id'] ?? ''}') ?? (isStandby ? -1 : 0));
    return AfterProdAssignment(
      jobId: isStandby ? -1 : parsedId,
      jobName: jobName,
      emoji: rawEmoji.isNotEmpty ? rawEmoji : AfterProdEngine.jobEmoji(jobName),
      requiredPeople: j['required_people'] is num
          ? (j['required_people'] as num).toInt()
          : (members.isNotEmpty ? members.length : 1),
      members: members,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'job_id': jobId,
        'job': jobName,
        'job_name': jobName,
        'emoji': emoji,
        'required_people': requiredPeople,
        'petugas': members,
        'members': members,
        'assigned_members': members.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n'),
        'status': status,
      };
}

class AfterProdHistoryRecord {
  const AfterProdHistoryRecord({
    required this.date,
    required this.shift,
    required this.jamPulang,
    required this.presentCount,
    required this.requiredCount,
    required this.assignments,
  });

  final String date;
  final String shift;
  final String jamPulang;
  final int presentCount;
  final int requiredCount;
  final List<AfterProdAssignment> assignments;

  factory AfterProdHistoryRecord.fromJson(Map<String, dynamic> j) {
    final rawList = (j['tasks'] is List ? j['tasks'] : j['assignments']) as List? ?? const [];
    final assignments = rawList
        .whereType<Map>()
        .map((e) => AfterProdAssignment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final totalAssigned = assignments.fold<int>(0, (acc, a) => acc + a.members.length);
    return AfterProdHistoryRecord(
      date: '${j['date'] ?? j['tanggal'] ?? ''}',
      shift: '${j['shift'] ?? 'RED'}'.toUpperCase(),
      jamPulang: '${j['jamPulang'] ?? j['jam_pulang'] ?? '18.15'}',
      presentCount: j['present_count'] is num ? (j['present_count'] as num).toInt() : totalAssigned,
      requiredCount: j['required_count'] is num ? (j['required_count'] as num).toInt() : totalAssigned,
      assignments: assignments,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'shift': shift,
        'jam_pulang': jamPulang,
        'jamPulang': jamPulang,
        'present_count': presentCount,
        'required_count': requiredCount,
        'tasks': assignments.map((e) => e.toJson()).toList(),
        'assignments': assignments.map((e) => e.toJson()).toList(),
      };
}

class AfterProdEngine {
  AfterProdEngine._();

  /// 1:1 with `getJobEmoji` in `ubnetwork/app/productivity/afterproduksi/page.tsx`.
  static String jobEmoji(String jobName) {
    final name = jobName.toLowerCase();
    if (name.contains('sampah') || name.contains('limbah')) return '🗑️';
    if (name.contains('galon') || name.contains('air') || name.contains('minum')) return '💧';
    if (name.contains('tamu') || name.contains('meeting') || name.contains('office')) return '🤝';
    if (name.contains('standby') || name.contains('sisa') || name.contains('extra')) return '💡';
    if (name.contains('area') || name.contains('oasis') || name.contains('agv')) return '🌳';
    if (name.contains('robot') || name.contains('pit')) return '🤖';
    if (name.contains('tool') || name.contains('gun') || name.contains('jig')) return '🛠️';
    return '🛠️';
  }

  /// 1:1 with `executeGenerateJobs` in `ubnetwork/app/productivity/afterproduksi/page.tsx`:
  /// - Shuffles eligible present TMs (excludes GL & TL)
  /// - Prioritizes active jobs matching shift scope (`COMMON` or `shift`) with `vokasi` in `allowedStatuses`
  /// - Filters allowed status & prioritizes matching `preferredLine`
  /// - Marks jobs with insufficient MP as `Off (Kekurangan MP)`
  /// - Places remaining TMs in `Standby / Extra` (`Sisa MP`)
  static List<AfterProdAssignment> generateAssignments({
    required List<AfterProdMember> members,
    required List<AfterProdJob> jobs,
    required String shift,
    int? seed,
  }) {
    final rng = seed != null ? Random(seed) : Random();
    final pool = members.where((m) => m.isEligibleFor5S && m.present).toList()..shuffle(rng);

    final activeJobs = jobs
        .where((j) => j.isActive && (j.scope == 'COMMON' || j.scope == shift.toUpperCase()))
        .toList();

    // Prioritize jobs that explicitly allow/restrict Vokasi first so they don't starve
    activeJobs.sort((a, b) {
      final aV = a.allowedStatuses.length == 1 && a.prioritizesVokasi ? 0 : (a.prioritizesVokasi ? 1 : 2);
      final bV = b.allowedStatuses.length == 1 && b.prioritizesVokasi ? 0 : (b.prioritizesVokasi ? 1 : 2);
      if (aV != bV) return aV.compareTo(bV);
      return a.id.compareTo(b.id);
    });

    final result = <AfterProdAssignment>[];

    for (final job in activeJobs) {
      final allowedLower = job.allowedStatuses.map((s) => s.toLowerCase()).toSet();
      final candidates = pool.where((m) {
        if (allowedLower.isEmpty || allowedLower.length >= 3) return true;
        return allowedLower.any(
          (a) => m.statusKaryawan.toLowerCase().contains(a) || a.contains(m.statusKaryawan.toLowerCase()),
        );
      }).toList();

      // Prioritize matching preferredLine
      if (job.preferredLine.isNotEmpty && job.preferredLine.toLowerCase() != 'all') {
        final pref = job.preferredLine.toLowerCase();
        candidates.sort((a, b) {
          final am = a.line.toLowerCase().contains(pref) ? 0 : 1;
          final bm = b.line.toLowerCase().contains(pref) ? 0 : 1;
          return am.compareTo(bm);
        });
      }

      if (candidates.length < job.requiredPeople) {
        result.add(
          AfterProdAssignment(
            jobId: job.id,
            jobName: job.name,
            emoji: job.emoji.isNotEmpty ? job.emoji : jobEmoji(job.name),
            requiredPeople: job.requiredPeople,
            members: const [],
            status: 'Off (Kekurangan MP)',
          ),
        );
        continue;
      }

      final picked = candidates.take(job.requiredPeople).toList();
      for (final p in picked) {
        pool.removeWhere((m) => m.id == p.id && m.name == p.name);
      }

      result.add(
        AfterProdAssignment(
          jobId: job.id,
          jobName: job.name,
          emoji: job.emoji.isNotEmpty ? job.emoji : jobEmoji(job.name),
          requiredPeople: job.requiredPeople,
          members: picked.map((e) => e.name).toList(),
          status: 'Terisi',
        ),
      );
    }

    if (pool.isNotEmpty) {
      result.add(
        AfterProdAssignment(
          jobId: -1,
          jobName: 'Standby / Extra',
          emoji: '💡',
          requiredPeople: 0,
          members: pool.map((e) => e.name).toList(),
          status: 'Sisa MP',
        ),
      );
    }

    return result;
  }

  /// Moves [memberName] from [fromJobIdx] to [toJobIdx] (1:1 with web `moveMember`).
  static List<AfterProdAssignment> moveMember({
    required List<AfterProdAssignment> assignments,
    required int fromJobIdx,
    required String memberName,
    required int toJobIdx,
  }) {
    if (fromJobIdx == toJobIdx ||
        fromJobIdx < 0 ||
        fromJobIdx >= assignments.length ||
        toJobIdx < 0 ||
        toJobIdx >= assignments.length) {
      return assignments;
    }
    final next = List<AfterProdAssignment>.from(assignments);
    final srcRow = next[fromJobIdx];
    final dstRow = next[toJobIdx];
    if (!srcRow.members.contains(memberName)) return assignments;

    final srcMembers = List<String>.from(srcRow.members)..remove(memberName);
    final dstMembers = List<String>.from(dstRow.members);
    if (!dstMembers.contains(memberName)) {
      dstMembers.add(memberName);
    }

    final srcIsStandby = srcRow.jobId == -1 || srcRow.status == 'Sisa MP';
    final dstIsStandby = dstRow.jobId == -1 || dstRow.status == 'Sisa MP';

    next[fromJobIdx] = srcRow.copyWith(
      members: srcMembers,
      status: srcIsStandby
          ? 'Sisa MP'
          : (srcMembers.isEmpty ? 'Off (Kekurangan MP)' : 'Terisi'),
    );
    next[toJobIdx] = dstRow.copyWith(
      members: dstMembers,
      status: dstIsStandby ? 'Sisa MP' : 'Terisi',
    );
    return next;
  }

  /// Swaps two assigned members 1-on-1 (1:1 with web `swapMembers`).
  static List<AfterProdAssignment> swapMembers({
    required List<AfterProdAssignment> assignments,
    required int aJobIdx,
    required int aMemberIdx,
    required int bJobIdx,
    required int bMemberIdx,
  }) {
    if (aJobIdx == bJobIdx && aMemberIdx == bMemberIdx) return assignments;
    if (aJobIdx < 0 || aJobIdx >= assignments.length || bJobIdx < 0 || bJobIdx >= assignments.length) {
      return assignments;
    }
    final rowA = assignments[aJobIdx];
    final rowB = assignments[bJobIdx];
    if (aMemberIdx < 0 || aMemberIdx >= rowA.members.length || bMemberIdx < 0 || bMemberIdx >= rowB.members.length) {
      return assignments;
    }

    final next = List<AfterProdAssignment>.from(assignments);
    final nameA = rowA.members[aMemberIdx];
    final nameB = rowB.members[bMemberIdx];

    if (aJobIdx == bJobIdx) {
      final list = List<String>.from(rowA.members);
      list[aMemberIdx] = nameB;
      list[bMemberIdx] = nameA;
      next[aJobIdx] = rowA.copyWith(members: list);
    } else {
      final listA = List<String>.from(rowA.members);
      final listB = List<String>.from(rowB.members);
      listA[aMemberIdx] = nameB;
      listB[bMemberIdx] = nameA;
      next[aJobIdx] = rowA.copyWith(members: listA);
      next[bJobIdx] = rowB.copyWith(members: listB);
    }
    return next;
  }

  static String buildWhatsappText({
    required String date,
    required String shift,
    required String jamPulang,
    required List<AfterProdAssignment> assignments,
  }) {
    final buf = StringBuffer()
      ..writeln('*TUGAS AFTER PRODUKSI 5S — UB ASSY*')
      ..writeln('Tanggal: $date | Shift: $shift')
      ..writeln('Target Pulang: $jamPulang WIB')
      ..writeln('');
    for (final a in assignments) {
      if (a.status == 'Off (Kekurangan MP)') {
        buf.writeln('${a.emoji} ${a.jobName}: _Off (Kekurangan MP)_');
      } else {
        buf.writeln('${a.emoji} ${a.jobName}: ${a.members.join(', ')}');
      }
    }
    return buf.toString().trim();
  }
}

// =============================================================================
// 2. TASK MANAGER POST-IT HUB MODELS & GANTT ENGINE
// =============================================================================
class TaskHubItem {
  const TaskHubItem({
    required this.id,
    required this.title,
    required this.moduleName,
    required this.status, // To Do | In Progress | In Review | Done
    required this.priority, // Urgent | High | Medium | Low
    required this.assignee,
    this.shift = 'RED',
    this.estimasiHari = 1,
    this.notes = '',
  });

  final int id;
  final String title;
  final String moduleName;
  final String status;
  final String priority;
  final String assignee;
  final String shift;
  final int estimasiHari;
  final String notes;

  TaskHubItem copyWith({
    int? id,
    String? title,
    String? moduleName,
    String? status,
    String? priority,
    String? assignee,
    String? shift,
    int? estimasiHari,
    String? notes,
  }) {
    return TaskHubItem(
      id: id ?? this.id,
      title: title ?? this.title,
      moduleName: moduleName ?? this.moduleName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      shift: shift ?? this.shift,
      estimasiHari: estimasiHari ?? this.estimasiHari,
      notes: notes ?? this.notes,
    );
  }

  factory TaskHubItem.fromJson(Map<String, dynamic> j) => TaskHubItem(
        id: j['id'] is num ? (j['id'] as num).toInt() : 0,
        title: '${j['nama_task'] ?? j['title'] ?? ''}'.trim(),
        moduleName: '${j['pekerjaan_nama'] ?? j['module_name'] ?? 'Umum'}'.trim(),
        status: '${j['status'] ?? 'To Do'}'.trim(),
        priority: '${j['priority'] ?? 'Medium'}'.trim(),
        assignee: '${j['assignee'] ?? 'Unassigned'}'.trim(),
        shift: '${j['shift'] ?? 'RED'}'.trim().toUpperCase(),
        estimasiHari: j['estimasi_hari'] is num ? (j['estimasi_hari'] as num).toInt() : 1,
        notes: '${j['notes'] ?? ''}'.trim(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'module_name': moduleName,
        'status': status,
        'priority': priority,
        'assignee': assignee,
        'shift': shift,
        'estimasi_hari': estimasiHari,
        'notes': notes,
      };
}

class TaskTimelineSlot {
  const TaskTimelineSlot({
    required this.task,
    required this.startOffset,
    required this.duration,
    required this.endDay,
  });

  final TaskHubItem task;
  final int startOffset;
  final int duration;
  final int endDay;
}

class TaskHubEngine {
  TaskHubEngine._();

  static const Map<String, int> _priorityWeight = {
    'Urgent': 1,
    'High': 2,
    'Medium': 3,
    'Low': 4,
  };

  /// 1:1 with `timelineSchedule` in `ubnetwork/app/task/page.tsx`.
  static ({List<TaskTimelineSlot> slots, int totalDays}) buildUrgencyTimeline(List<TaskHubItem> tasks) {
    int pw(String p) => _priorityWeight[p] ?? 3;

    final inProgress = tasks.where((t) => t.status == 'In Progress').toList()
      ..sort((a, b) => pw(a.priority).compareTo(pw(b.priority)));

    final pending = tasks.where((t) => t.status != 'In Progress' && t.status != 'Done').toList()
      ..sort((a, b) {
        final c = pw(a.priority).compareTo(pw(b.priority));
        if (c != 0) return c;
        final sa = a.status == 'In Review' ? 1 : 2;
        final sb = b.status == 'In Review' ? 1 : 2;
        if (sa != sb) return sa.compareTo(sb);
        return a.estimasiHari.compareTo(b.estimasiHari);
      });

    final completed = tasks.where((t) => t.status == 'Done').toList();

    final slots = <TaskTimelineSlot>[];
    var maxProgEnd = 1;

    for (final t in inProgress) {
      final dur = max(1, t.estimasiHari);
      slots.add(TaskTimelineSlot(task: t, startOffset: 0, duration: dur, endDay: dur));
      if (dur > maxProgEnd) maxProgEnd = dur;
    }

    var cursor = inProgress.isNotEmpty ? maxProgEnd : 0;
    for (final t in pending) {
      final dur = max(1, t.estimasiHari);
      slots.add(TaskTimelineSlot(task: t, startOffset: cursor, duration: dur, endDay: cursor + dur));
      cursor += dur;
    }

    for (final t in completed) {
      final dur = max(1, t.estimasiHari);
      slots.add(TaskTimelineSlot(task: t, startOffset: 0, duration: dur, endDay: dur));
    }

    return (slots: slots, totalDays: max(cursor, 14));
  }
}

// =============================================================================
// 3. MASTER SHIFT TEMPLATE MODELS & MATH
// =============================================================================
class ShiftTemplateSlot {
  const ShiftTemplateSlot({
    required this.slotNo,
    required this.startTime,
    required this.endTime,
    required this.durationMin,
    this.isOvertime = false,
    this.isActive = true,
    this.breakAfterMin = 0,
    this.note = '',
  });

  final int slotNo;
  final String startTime;
  final String endTime;
  final int durationMin;
  final bool isOvertime;
  final bool isActive;
  final int breakAfterMin;
  final String note;

  String get timeRange => '$startTime - $endTime';

  int dynamicPlan(double taktTime) {
    if (!isActive || taktTime <= 0 || durationMin <= 0) return 0;
    return (durationMin / taktTime).round();
  }

  ShiftTemplateSlot copyWith({
    int? slotNo,
    String? startTime,
    String? endTime,
    int? durationMin,
    bool? isOvertime,
    bool? isActive,
    int? breakAfterMin,
    String? note,
  }) {
    return ShiftTemplateSlot(
      slotNo: slotNo ?? this.slotNo,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMin: durationMin ?? this.durationMin,
      isOvertime: isOvertime ?? this.isOvertime,
      isActive: isActive ?? this.isActive,
      breakAfterMin: breakAfterMin ?? this.breakAfterMin,
      note: note ?? this.note,
    );
  }

  factory ShiftTemplateSlot.fromJson(Map<String, dynamic> j) => ShiftTemplateSlot(
        slotNo: j['slot_no'] is num ? (j['slot_no'] as num).toInt() : 1,
        startTime: '${j['start_time'] ?? '07:15'}',
        endTime: '${j['end_time'] ?? '08:15'}',
        durationMin: j['duration_min'] is num ? (j['duration_min'] as num).toInt() : 60,
        isOvertime: j['is_overtime'] == true || j['is_overtime'] == 1,
        isActive: j['is_active'] == null ? true : (j['is_active'] == true || j['is_active'] == 1),
        breakAfterMin: j['break_after_min'] is num ? (j['break_after_min'] as num).toInt() : 0,
        note: '${j['note'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'slot_no': slotNo,
        'start_time': startTime,
        'end_time': endTime,
        'time_range': timeRange,
        'duration_min': durationMin,
        'is_overtime': isOvertime ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'break_after_min': breakAfterMin,
        'note': note,
      };
}

class ShiftTemplateModel {
  const ShiftTemplateModel({
    required this.code,
    required this.name,
    required this.category, // normal | puasa
    required this.dayType,
    this.defaultTaktTime = 2.4,
    this.regularHours = 7.5,
    this.isActive = true,
    this.description = '',
    required this.slots,
  });

  final String code;
  final String name;
  final String category;
  final String dayType;
  final double defaultTaktTime;
  final double regularHours;
  final bool isActive;
  final String description;
  final List<ShiftTemplateSlot> slots;

  ShiftTemplateModel copyWith({
    String? name,
    String? category,
    String? dayType,
    double? defaultTaktTime,
    double? regularHours,
    bool? isActive,
    String? description,
    List<ShiftTemplateSlot>? slots,
  }) {
    return ShiftTemplateModel(
      code: code,
      name: name ?? this.name,
      category: category ?? this.category,
      dayType: dayType ?? this.dayType,
      defaultTaktTime: defaultTaktTime ?? this.defaultTaktTime,
      regularHours: regularHours ?? this.regularHours,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      slots: slots ?? this.slots,
    );
  }

  factory ShiftTemplateModel.fromJson(Map<String, dynamic> j) {
    final rawSlots = j['slots'] is List ? j['slots'] as List : const [];
    return ShiftTemplateModel(
      code: '${j['code'] ?? 'NORMAL_DAY'}',
      name: '${j['name'] ?? 'Shift Normal'}',
      category: '${j['category'] ?? 'normal'}',
      dayType: '${j['day_type'] ?? 'Senin - Kamis'}',
      defaultTaktTime: j['default_takt_time'] is num ? (j['default_takt_time'] as num).toDouble() : 2.4,
      regularHours: j['regular_hours'] is num ? (j['regular_hours'] as num).toDouble() : 7.5,
      isActive: j['is_active'] == null ? true : (j['is_active'] == true || j['is_active'] == 1),
      description: '${j['description'] ?? ''}',
      slots: rawSlots
          .whereType<Map>()
          .map((e) => ShiftTemplateSlot.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'category': category,
        'shift': 'GLOBAL',
        'day_type': dayType,
        'default_takt_time': defaultTaktTime,
        'regular_hours': regularHours,
        'is_active': isActive ? 1 : 0,
        'description': description,
        'slots': slots.map((e) => e.toJson()).toList(),
      };
}

class ShiftTemplateMath {
  ShiftTemplateMath._();

  static ({int planRegular, int planFullOt, double totalHours, int activeSlots}) computeSummary(
    List<ShiftTemplateSlot> slots,
    double taktTime,
  ) {
    var planRegular = 0;
    var planFullOt = 0;
    var totalMin = 0;
    var activeCount = 0;
    for (final s in slots) {
      if (!s.isActive) continue;
      activeCount++;
      final p = s.dynamicPlan(taktTime);
      planFullOt += p;
      if (!s.isOvertime) planRegular += p;
      totalMin += s.durationMin;
    }
    return (
      planRegular: planRegular,
      planFullOt: planFullOt,
      totalHours: double.parse((totalMin / 60.0).toStringAsFixed(1)),
      activeSlots: activeCount,
    );
  }
}

// =============================================================================
// 4. KAIZEN REPORT PRODUCTIVITY MODELS
// =============================================================================
class ProdKaizenItem {
  const ProdKaizenItem({
    required this.id,
    required this.tag,
    required this.month, // YYYY-MM
    required this.theme,
    required this.lineProcess,
    required this.pic,
    required this.beforeValue,
    required this.afterValue,
    required this.status, // SUDAH | ON PROGRES | BELUM
    this.rootCause = '',
    this.countermeasure = '',
    this.sourceChokoteiKey = '',
  });

  final String id;
  final String tag;
  final String month;
  final String theme;
  final String lineProcess;
  final String pic;
  final String beforeValue;
  final String afterValue;
  final String status;
  final String rootCause;
  final String countermeasure;
  final String sourceChokoteiKey;

  ProdKaizenItem copyWith({
    String? tag,
    String? month,
    String? theme,
    String? lineProcess,
    String? pic,
    String? beforeValue,
    String? afterValue,
    String? status,
    String? rootCause,
    String? countermeasure,
    String? sourceChokoteiKey,
  }) {
    return ProdKaizenItem(
      id: id,
      tag: tag ?? this.tag,
      month: month ?? this.month,
      theme: theme ?? this.theme,
      lineProcess: lineProcess ?? this.lineProcess,
      pic: pic ?? this.pic,
      beforeValue: beforeValue ?? this.beforeValue,
      afterValue: afterValue ?? this.afterValue,
      status: status ?? this.status,
      rootCause: rootCause ?? this.rootCause,
      countermeasure: countermeasure ?? this.countermeasure,
      sourceChokoteiKey: sourceChokoteiKey ?? this.sourceChokoteiKey,
    );
  }

  factory ProdKaizenItem.fromJson(Map<String, dynamic> j) => ProdKaizenItem(
        id: '${j['id'] ?? ''}',
        tag: '${j['tag'] ?? 'PRODUCTIVITY'}',
        month: '${j['month'] ?? ''}',
        theme: '${j['theme'] ?? j['title'] ?? ''}',
        lineProcess: '${j['line_process'] ?? 'UB Assy'}',
        pic: '${j['pic'] ?? ''}',
        beforeValue: '${j['before_value'] ?? ''}',
        afterValue: '${j['after_value'] ?? ''}',
        status: '${j['status'] ?? 'ON PROGRES'}'.toUpperCase(),
        rootCause: '${j['root_cause'] ?? ''}',
        countermeasure: '${j['countermeasure'] ?? ''}',
        sourceChokoteiKey: '${j['source_chokotei_key'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tag': tag,
        'month': month,
        'theme': theme,
        'line_process': lineProcess,
        'pic': pic,
        'before_value': beforeValue,
        'after_value': afterValue,
        'status': status,
        'root_cause': rootCause,
        'countermeasure': countermeasure,
        'source_chokotei_key': sourceChokoteiKey,
      };
}
