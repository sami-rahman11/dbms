# UIU Dock

A database-driven course resource center, online group study and course-wise
help platform for UIU students — built as a **Database Management System Lab**
project (Summer 2026).

Three pillars in one dock:

1. **Resource Hub** — searchable, versioned course materials (notes, slides,
   past questions, lab sheets, links) with ratings, download tracking and
   staff moderation.
2. **Study Rooms** — course-specific virtual rooms with scheduling, capacity,
   host controls and attendance.
3. **Help Desk** — persistent **per-course group chats** (pick a course →
   enter its chat) with presence, searchable history and staff moderation
   (flag review, ban, timed mute, audit trail).

Staff get a separate console (own theme, own sign-in) with approve/reject,
room/chat moderation, a reports inbox, user suspend/wipe and analytics.
Students never see admin UI.

## Tech stack

| Layer    | Current (prototype)              | Planned (backend)              |
| -------- | -------------------------------- | ------------------------------ |
| Frontend | Plain HTML / CSS / JS, no build  | Same, wired to REST + Socket.IO |
| Data     | Seed JSON + `localStorage` demo  | MySQL (normalized, 3NF, FULLTEXT) |
| Auth     | Mock accounts in-browser         | JWT + bcrypt, Student/Admin RBAC |
| Realtime | Simulated                        | Node.js + Express + Socket.IO  |

## Project structure

```
dbms/
├── frontend/          # the web app (open index.html)
│   ├── index.html     # landing
│   ├── resources.html # Resource Hub
│   ├── rooms.html     # Study Rooms
│   ├── help-desk.html # course-wise group chats
│   ├── login.html     # student login + create account
│   ├── admin.html     # separate staff console + sign-in
│   ├── css/styles.css
│   └── js/            # seed.js (demo data), store.js (persistence, auth, gates)
├── docs/              # official project proposal (PDF)
├── README.md
├── LICENSE
└── .gitignore
```

## Quickstart

No build step, no dependencies.

```bash
# option 1: open directly
open frontend/index.html        # or double-click it

# option 2: serve locally (any static server)
cd frontend && python -m http.server 8000
# → http://localhost:8000/index.html
```

**Demo flows**

- *Student*: Login page → **Create account** (name + student ID) → upload
  resources, join rooms, chat per course. Guests can browse; uploads,
  downloads, joins and chat require an account.
- *Staff*: `admin.html` → sign in with `admin` / `admin123` → moderate
  resources, rooms, chats, reports and users.

> Demo data is synthetic and browser-local (`localStorage` key
> `uiu_dock_v1`). Use **Reset Demo Data** in the staff console to reseed.

## Course context

- **Course:** Database Management System Lab — Dept. of CSE, UIU
- **Faculty:** Robiul Islam, Lecturer
- **Team:** Baseline (Section H), Summer 2026 — 262
- **Members:** Fahim Mahmud (0112430687) · Raysa Sanjana (0112420576) ·
  Nur Al Amin (0112410279) · Prantick Kumer Dey (011221146) ·
  Sami Rahman (0112410312)
- Full scope, benchmark analysis and schema plan: `docs/` proposal PDF.

## Contributing

Small academic team workflow: branch per feature (`feature/<name>`),
open a PR into `main`, one reviewer. Keep UI copy simple; keep
student/admin surfaces separate; never commit real credentials
(`.env` is git-ignored).

## License

MIT — see [LICENSE](LICENSE).
