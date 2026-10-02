# PROJECT FINAL REPORT

## UIU DOCK — Resource Center, Virtual Study Rooms & Help Desk

**Course:** Database Management System Lab
**Submitted To:** Robiul Islam, Lecturer, Department of CSE, UIU
**Submitted By:** Baseline

| Team Member | Student ID |
|---|---|
| Fahim Mahmud | 0112430687 |
| Raysa Sanjana | 0112420576 |
| Nur Al Amin | 0112410279 |
| Prantick Kumer Dey | 011221146 |
| Sami Rahman | 0112410312 |

**Group Name:** Baseline — **Section:** H — **Semester:** Summer 2026 (262)

---

## Introduction

In university education, effective learning depends not only on lectures but also on access to organized resources and consistent peer collaboration. Students need a reliable place to find verified course materials — lecture notes, slides, question banks, lab sheets, and reference links — and a structured way to study together and discuss course-specific problems. Without such infrastructure, learning becomes fragmented and heavily dependent on informal, scattered sharing.

Course resources are often dispersed across personal drives, senior batches, scattered messaging groups, and unorganized social media posts. There is no single searchable hub where resources are categorized by course, subject, semester, and type, with version control, ratings, and authenticity. Similarly, online group study is usually limited to ad-hoc video calls without course-specific rooms, scheduling, attendance, or shared materials. For day-to-day problem solving, students lack a dedicated course-wise discussion space — general groups mix many courses together, so course-specific questions and solutions get lost.

UIU Dock was proposed as a centralized, database-driven web platform unifying three core academic needs in one system: (1) a Resource Center / Hub for course-wise sharing and discovery, (2) Online Group Study Rooms for course-specific collaborative learning, and (3) a Help Desk Center implemented as persistent course-wise group chats. This report documents the final state of the project: a working full-stack implementation (PHP + MySQL on XAMPP) alongside a static frontend prototype, backed by a normalized 3NF relational schema with keys, constraints, indexes, full-text search, views, transactions, and demonstrable analytical queries — with role-based access for students and administrators, moderation with audit trails, and course-contextualized activity throughout.

---

## 1. Project Changes & Justification

### 1A. Originally proposed features that could not be implemented

1. **Email/SMTP notifications.**
   Requires mail infrastructure unavailable in the lab. In-app notifications (bell, broadcasts, per-type preferences, read tracking) cover every notification scenario in the proposal's workflows.
2. **Text reviews on resources and room detail extras (waiting lists, session reminders, bookmarks).**
   Ratings (now true 1–5 votes) satisfy the ratings requirement; full text reviews, reminder mails, and bookmarks were cut to protect the three core pillars within the semester. Room-full and download events are still recorded.
3. **Threaded chat replies in the UI.**
   The schema carries `reply_to_id`, but the interface ships flat messages with pins and code blocks. True threading UI was deferred; pins plus per-course search cover the "find the solution again" need.
4. **Duplicate detection via file hashing and storage quotas.**
   Dropped with the links-only scope decision: resources link out to external drives (no file bytes touch our database), so hashing adds no value; chat attachments live on local disk with type/size caps instead.
5. **Room "Leave" button.**
   Removed deliberately during final UI review: leaving happens on the external meeting platform (Meet/Zoom), so an in-app Leave control was misleading. Joining (attendance) remains.

### 1B. New features added beyond the proposal

1. **1–5 star rating modal with hover preview and labels** — replaced the prototype's single "+0.1" Rate button, because real votes make the average-rating analytics (and the `AVG` SQL coverage) meaningful.
2. **Report resolution workflow** — one-click Resolve was not real moderation. Staff now open a review modal showing the reported content live, pick an outcome (dismiss / remove / close), write a note to the reporter, and confirm a review checkbox before anything applies.
3. **Complain Box** — a direct staff-inbox channel for general complaints, which content-attached reports could not express.
4. **Notification bell with per-type preferences and read tracking** — makes the proposal's notification requirement actually usable instead of noisy.
5. **Settings page** — profile rename (propagated across authored content), password change, notification prefs, content wipe and account delete; covers the profile-management deliverable.
6. **Trust scores, timed (7-day) mutes, per-user upload/course-add permissions, and a visible audit trail** — graduated moderation between "do nothing" and "ban".
7. **Staff-managed course catalog with propose flow and in-use guard** — courses can grow without code changes, and deletion is blocked while content references a course (FK `RESTRICT`).
8. **Chat composer upgrades** — staged attachments (5 files, 5 MB, extension allowlist), one-click code-snippet insert with formatting, pins, and per-chat search.
9. **Per-event download log + cached counters, transactional admin actions, atomic room joins** — analytics-ready data with integrity under concurrency.

---

## 2. Final Project Features

1. **Landing / Home** — Hero with live course list and at-a-glance counts of resources, rooms, courses, and messages. Entry point linking the three pillars.
2. **Resource Hub** — Searchable, filterable (course/type), sortable (downloads/rating) catalog of verified, versioned course materials. Only approved content is discoverable.
3. **Resource Upload & Moderation Queue** — Members submit title/course/type/link for review; staff approve, reject, or remove with notifications and audit entries. Guests are gated to registration.
4. **1–5 Star Rating** — Goodreads-style modal with hover preview and Terrible→Excellent labels; one vote per user per resource, re-votable, averaged live on every card.
5. **Download Tracking** — Each download increments the counter, redirects to the external file, and writes a per-event log row for analytics. Requires an account.
6. **Study Rooms** — Course-specific rooms with topic, schedule, capacity (2–50), host, and meeting link. Creation is member-gated and validated.
7. **Room Join & Attendance** — Join records membership (capacity-enforced, race-safe); rooms show live occupancy; staff can close stale or reported rooms.
8. **Help Desk Group Chats** — Persistent per-course chats: pick a course, enter its dedicated discussion with full history. Guests see a members-only gate.
9. **Chat Attachments & Code Snippets** — Up to 5 staged files per message (images/documents, validated) stored on the server, plus one-click SQL/code blocks with formatting.
10. **Message Search, Pins & Reporting** — Per-chat keyword search, staff pinnable solutions, and one-click reporting of abusive or spam messages.
11. **Reporting System** — Students report resources, rooms, or messages with reasons; every report lands in the staff inbox with reporter, target, and status.
12. **Resolution Workflow** — Staff review the reported content live, choose dismiss/remove/close, add a reporter-facing note, verify review via checkbox, and confirm — side effects applied atomically.
13. **Complain Box** — Free-form complaints (subject/category/course/details) filed to staff, with personal complaint history and statuses.
14. **Notifications & Preferences** — Bell with unread badge and dropdown (approvals, resolutions, announcements, broadcasts), mark-all-read, and per-type opt-outs in Settings.
15. **Settings & Account** — Rename profile, change password (verified current), view granted permissions, manage notification prefs, wipe own content, or delete the account.
16. **Staff Console Overview** — Pending uploads, open reports, suspended/muted counts, recent activity, and trust-and-safety cards with live counts.
17. **Course Catalog Management** — Staff add courses (live instantly in filters and chats) or remove empty ones; members with permission can propose courses.
18. **User Moderation** — Per-contributor activity table with suspend/unsuspend, timed mute, upload/course-add permission toggles, and full content wipe, all audit-logged.
19. **Audit Trail** — Append-only log of every staff action (actor, action, target, time), surfaced on flag cards and the overview, capped for performance.
20. **Authentication & Roles** — Student registration/login (name + student ID + bcrypt password, lockout on repeated failure) and a separate staff sign-in; students can never reach admin UI.
