# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Frontend-only for current milestone: static HTML/CSS/JS (local / XAMPP demo, no build step). Planned full system: backend + MySQL (normalized 3NF) — not yet implemented; auth, real-time chat, and notifications are dummy/simulated in the frontend for now.

## Users

Primary: UIU CSE students (Summer 2026, DBMS Lab context) studying enrolled courses, seeking verified materials, course-specific study partners, and quick peer help. Secondary: Administrators / moderators (course staff, Team Baseline) governing users, courses, content quality, and chat conduct.

## Product Purpose

UIU Dock is a centralized, database-driven web prototype that unifies three academic needs in one course-contextualized system: (1) searchable Resource Center/Hub, (2) schedulable course-specific Online Group Study Rooms, (3) Help Desk as persistent course-wise group chats (select course → enter dedicated chat). It exists because materials are scattered across drives/chats, study sessions are ad-hoc without course context, and mixed-course groups bury course-specific Q&A. Success is demonstrable end-to-end workflows — contribute/discover resources, schedule/join rooms, discuss/search per-course chat history — backed by a normalized relational model with integrity, auditability, and analytics.

## Positioning

The only UIU-focused system combining verified resource repository with versioning/ratings, scheduled study rooms with capacity/presence/attendance/shared resources, and persistent per-course help chats with searchable archives — all linked through one normalized MySQL model with ERD, indexes, full-text search, and analytical queries (most-accessed resources, active rooms/chats, contributors, trends).

## Operating Context

Browser-based unified dashboard where all activity is course-contextualized. Current milestone is frontend-only for project update: register/login, enroll/select courses, browse resources, schedule/join study rooms, and per-course group chat are clickable UI backed by dummy data (no live backend). Planned workflows once backend lands: register/login → enroll/select courses → browse/upload/rate resources (pending → approved), create/discover/schedule/join study rooms (with external meeting links, reminders, attendance), browse course list → join per-course group chat (real-time messaging, pins, threads, search). Admin workflow (planned): approve/reject, handle reports, manage users/courses/rooms/chats, announcements, analytics/audit. Dev context: Git/GitHub, local XAMPP or Node dev env for frontend; MySQL Workbench/DBeaver and Postman/Socket.IO client testing apply to the planned backend phase.

## Capabilities and Constraints

Confirmed (frontend milestone): course/subject catalog with semester mapping (dummy data); resource browse/search/filter by course with external-link routing (e.g., Google Drive) — no uploads or local file handling; study-room create/schedule/join-leave UI with dummy presence/attendance; per-course group-chat UI with dummy messages, pins, and searchable history stubs; auth/RBAC and notifications simulated in the frontend.
Planned backend (deferred, not in current milestone): resource upload metadata, categorization/tags, versioning, ratings/reviews, download tracking, moderation queue + reporting + audit logs; room capacity/host-controls/reminders/shared-resource panel/session history; persistent chat with presence/typing + in-app and email/SMTP notifications; JWT/bcrypt auth with Student and Administrator RBAC and per-course chat membership; admin analytics.
Constraints: no file storage load on our end — resources link out to external storage (e.g., Drive), so no DB file hashing/quotas in scope for now; MySQL normalized (3NF) model with FKs/constraints/transactions/indexes/full-text is the planned contract, not yet live; WebSocket persistence with reconnect/fallback polling is planned, currently simulated.
Out of scope: automated grading, AI tutors, built-in video SFU, payments, plagiarism detection, SIS integration, native mobile apps, 1:1 tutoring queues.
Undecided (Q3 unanswered): real course list, seed resources/rooms/chat histories, logos/brand assets, accessibility standard — do not invent; label synthetic demo data where used.

## Brand Commitments

Name: UIU Dock. Academic DBMS Lab prototype voice (Team Baseline, Section H, Summer 2026). No confirmed logo, palette, type, or marketing assets.

## Evidence on Hand

- `UIU_Dock_Official_Project_Proposal.pdf` — normative scope, three pillars, benchmark, stack proposal, risks.
- `archive/` — prior Study Group Finder / Study Resource Hub proposals and pre-fix snapshots (background only).
- Absences future work must not fabricate: no real courses, resources, users, testimonials, customers, benchmarks, pricing, or brand assets on hand; author synthetic demo content at full fidelity and label it synthetic.

## Product Principles

1. Course context everywhere — every resource, room, message, and metric resolves to a course.
2. Verification before discovery — only moderated/approved content becomes searchable.
3. Persistence enables memory — chat and attendance history are queryable knowledge, never ephemeral.
4. Moderation sustains trust — reporting, versioning, pinning, and audit keep shared truth reliable.
5. Relational proof — every collaboration claim must be demonstrable in SQL.
