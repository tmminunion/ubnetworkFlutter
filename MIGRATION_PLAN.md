# UBnetwork Flutter — 1:1 Migration Plan & Todo

Dokumen ini menjadi acuan resmi migrasi 1:1 dari `ubnetwork` (Next.js Web) ke `ubnetworkFlutter` (Native Flutter Offline-First Android).

## Siklus Kerja Wajib per Pekerjaan
1. Baca kode sumber web `ubnetwork/app/...` secara menyeluruh (perbandingan 1:1).
2. Bangun model, store (offline-first + sync), dan layar native Flutter.
3. Tambah / perbarui unit test (`test/`).
4. Pengecekan total: commit, push ke `main`, verifikasi GitHub Actions (`Static Analysis` + `Run Unit Tests` + `Build APK & AAB`) hijau.
5. Update checklist di file ini dan pindah ke pekerjaan selanjutnya.

---

## Matriks Perbandingan 1:1 (Web vs Flutter)

| Area / Route | Modul Web | Status Flutter | Catatan |
| :--- | :--- | :--- | :--- |
| `/` (Home Hub) | Top Bar macOS, Display & Monitor, 6 Pilar `SQPCEHR`, 5 Kaizen, 11 Quick App | **Selesai (1:1)** | `lib/features/hub/hub_screen.dart` |
| `/display` (GL Board Hub) | 7 Pilar × 4 Kertas KPI (28 board) | **Shell 1:1** | `lib/features/hub/display_board_screen.dart` |
| `/productivity` | 14 modul | **3 / 14 Native** | `checksheet` (A3), `print` (PDF A3), `settings` |
| `/safety` | 8 modul | **2 / 8 Native** | `/safety/temuan` (1.1) & `/kyt/monitoring` (1.2) selesai |
| `/quality` | 6 modul | **Shell 1:1** | Target Fase 2 |
| `/cost` | 6 modul | **Shell 1:1** | Target Fase 4 |
| `/hr` | 9 modul | **Shell 1:1** | Target Fase 5 |
| `/env` | 7 modul | **Shell 1:1** | Target Fase 4 |
| Kaizen & Quick App Dx | 5 Kaizen + 11 Quick App + `/monitor` | **Shell 1:1** | Target Fase 7 |

---

## Todo Bertahap

### Fase 0 — Fondasi & Hub 1:1
- [x] Home Hub 1:1 (`SQPCEHR`, `Display KPI`, `Monitor`, `Aktivitas Kaizen`, `UB Quick App Dx`)
- [x] Display KPI GL Management Board Hub (`/display`)
- [x] 6 Sub-Hub Shells (`/safety`, `/quality`, `/productivity`, `/cost`, `/hr`, `/env`)
- [x] Dokumen `MIGRATION_PLAN.md`

### Fase 1 — Pilar Safety (`/safety`)
- [x] **1.1** `/safety/temuan` — Temuan Safety (List Up Problem & Kaizen Report, Matriks Risiko Toyota Karawang Plant `Aa–Cc`, STOP 6, CRUD Offline-First + Sync)
- [x] **1.2** `/kyt/monitoring` — KYT Monitoring 12 Bulan (1 Bulan 1 KYT per Group SGA Red & White, Live Sync MySQL + Offline Cache)
- [ ] **1.3** `/safety/group` — Group SGA (Small Group Activity)
- [ ] **1.4** `/safety/device` — Safety Device & Interlock
- [ ] **1.5** `/safety/bira` — BIRA (Bimbingan & Arahan K3)
- [ ] **1.6** `/safety/kpi` — Safety KPI & Zero Accident

### Fase 2 — Pilar Quality (`/quality`)
- [ ] **2.1** `/quality/daily/out` — Defect Out Flow (Red & White, D/U otomatis, Kaizen)
- [ ] **2.2** `/quality/daily/in` — Defect In Proses (Red & White, D/U otomatis, Kaizen)

### Fase 3 — Pilar Productivity Lanjutan (`/productivity`)
- [ ] **3.1** `/productivity/monitoring` — Monitoring Produksi & Efisiensi 1–31
- [ ] **3.2** `/productivity/chokotei` & `/productivity/chokotei-manual`
- [ ] **3.3** `/productivity/cbu` & `/productivity/ckd` (Monitoring 1–31)
- [ ] **3.4** `/productivity/roster` & `/productivity/absensi`
- [ ] **3.5** `/productivity/after-prod`, `/productivity/tasks`, `/productivity/shift-template`, `/productivity/kaizen`

### Fase 4 — Pilar Cost (`/cost`) & Environment (`/env`)
- [ ] **4.1** `/cost/daily` & `/cost/temuan`
- [ ] **4.2** `/env/air-leakage` (`#lub` & `#klub`), `/env/daily` (kWh), `/env/temuan`

### Fase 5 — Pilar HR & Morale (`/hr`)
- [ ] **5.1** `/bacadoa` — Jadwal & Matrik Baca Doa Asare 1–31 (+ cetak A4)
- [ ] **5.2** `/hr/rankmp` — Rank MP
- [ ] **5.3** `/hr/idea`, `/idnu` (Idea), `/hr/temuan`

### Fase 6 — Display KPI 16:9 (`/display`) & Monitor (`/monitor`)
- [ ] **6.1** Kertas `Main KPI`, `Sub KPI`, `Proses KPI`, `Kaizen` (7 Pilar)
- [ ] **6.2** `/monitor` — Slide Show TV Shopfloor

### Fase 7 — Quick App Dx & Aktivitas Kaizen
- [ ] **7.1** Henkaten Board, Post-It Board, UBdrive, Andon Live Monitor, Dokumentasi
- [ ] **7.2** QCC, TPM, 5R / 5S, SW Observasi
