-- UIU Dock database schema (fixed from teammate draft).
-- Target: MySQL 8.0+ / XAMPP MariaDB 10.4+ (InnoDB, utf8mb4).
-- Import via phpMyAdmin (server-level Import tab works: DB is created + selected below),
-- or: CREATE DATABASE uiu_dock CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; then SOURCE this file.

CREATE DATABASE IF NOT EXISTS uiu_dock CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE uiu_dock;
--
-- Fixes vs teammate draft:
-- 1. Files are LINKS only (PRODUCT.md scope): dropped uploaded_files/message_files BLOB tables,
--    replaced with message_attachments(file_name/file_url). No LONGBLOB anywhere.
-- 2. resources.link is NULLABLE (upload form allows blank, resources.html).
-- 3. reports uses real nullable FK targets (course/resource/room/message) + CHECK, not a bare reference_id.
-- 4. notifications supports broadcasts (recipient_id NULL = everyone) + notification_reads join table
--    + type column (store.js: notify/for=null, prefs per type).
-- 5. Explicit ON DELETE rules: RESTRICT on course catalog (admin "in use" guard),
--    CASCADE on member/log/attachment rows, SET NULL on authorship/handlers.
-- 6. users.student_id stays UNIQUE + NULLABLE (admins have NULL; MySQL allows multiple NULLs).
-- 7. download_count is a DERIVED cache of resource_downloads (3NF exception, see docs/normalization.md).

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  student_id VARCHAR(40) UNIQUE,
  password_hash VARCHAR(100) NOT NULL,
  role ENUM('student','admin') NOT NULL DEFAULT 'student',
  suspended BOOLEAN NOT NULL DEFAULT FALSE,
  muted_until DATETIME NULL,
  can_upload BOOLEAN NOT NULL DEFAULT TRUE,
  can_add_course BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS courses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(30) NOT NULL UNIQUE,
  title VARCHAR(200) NOT NULL,
  semester VARCHAR(60) NOT NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_courses_creator FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS resources (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  type ENUM('Notes','Slides','Past Questions','Lab Sheet','Link') NOT NULL,
  link VARCHAR(2048) NULL,
  version VARCHAR(30) NOT NULL DEFAULT 'v1.0',
  uploaded_by BIGINT UNSIGNED NOT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  download_count INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_resources_course FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT,
  CONSTRAINT fk_resources_uploader FOREIGN KEY (uploaded_by) REFERENCES users (id) ON DELETE CASCADE,
  INDEX ix_resource_course_status (course_id, status),
  FULLTEXT KEY ft_resource_title (title)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS resource_ratings (
  resource_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  stars TINYINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (resource_id, user_id),
  CONSTRAINT chk_rating_range CHECK (stars BETWEEN 1 AND 5),
  CONSTRAINT fk_ratings_resource FOREIGN KEY (resource_id) REFERENCES resources (id) ON DELETE CASCADE,
  CONSTRAINT fk_ratings_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS resource_downloads (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  resource_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  downloaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_downloads_resource FOREIGN KEY (resource_id) REFERENCES resources (id) ON DELETE CASCADE,
  CONSTRAINT fk_downloads_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  INDEX ix_download_resource (resource_id),
  INDEX ix_download_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS rooms (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  host_id BIGINT UNSIGNED NOT NULL,
  scheduled_at DATETIME NOT NULL,
  capacity SMALLINT UNSIGNED NOT NULL,
  link VARCHAR(2048) NULL,
  status ENUM('active','closed') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_room_capacity CHECK (capacity BETWEEN 2 AND 50),
  CONSTRAINT fk_rooms_course FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT,
  CONSTRAINT fk_rooms_host FOREIGN KEY (host_id) REFERENCES users (id) ON DELETE CASCADE,
  INDEX ix_rooms_schedule (course_id, scheduled_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS room_members (
  room_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (room_id, user_id),
  CONSTRAINT fk_members_room FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
  CONSTRAINT fk_members_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  body TEXT NOT NULL,
  reply_to_id BIGINT UNSIGNED NULL,
  pinned BOOLEAN NOT NULL DEFAULT FALSE,
  deleted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_messages_course FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT,
  CONSTRAINT fk_messages_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_messages_reply FOREIGN KEY (reply_to_id) REFERENCES messages (id) ON DELETE SET NULL,
  INDEX ix_messages_course_time (course_id, created_at),
  FULLTEXT KEY ft_message_body (body)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Attachment metadata only: external links (Drive/meet), never file bytes.
CREATE TABLE IF NOT EXISTS message_attachments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  message_id BIGINT UNSIGNED NOT NULL,
  kind ENUM('pic','doc','link') NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_url VARCHAR(2048) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_attachments_message FOREIGN KEY (message_id) REFERENCES messages (id) ON DELETE CASCADE,
  INDEX ix_attachments_message (message_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS reports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reporter_id BIGINT UNSIGNED NOT NULL,
  kind ENUM('resource','room','message','complaint') NOT NULL,
  course_id BIGINT UNSIGNED NULL,
  resource_id BIGINT UNSIGNED NULL,
  room_id BIGINT UNSIGNED NULL,
  message_id BIGINT UNSIGNED NULL,
  reason TEXT NOT NULL,
  status ENUM('open','resolved','dismissed') NOT NULL DEFAULT 'open',
  handled_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reports_reporter FOREIGN KEY (reporter_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_course FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_resource FOREIGN KEY (resource_id) REFERENCES resources (id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_room FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_message FOREIGN KEY (message_id) REFERENCES messages (id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_handler FOREIGN KEY (handled_by) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT chk_report_target CHECK (
    (resource_id IS NOT NULL) OR (room_id IS NOT NULL) OR (message_id IS NOT NULL)
    OR (course_id IS NOT NULL) OR (kind = 'complaint')
  ),
  INDEX ix_report_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- recipient_id NULL = broadcast to every member (store.js notify/for=null).
CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recipient_id BIGINT UNSIGNED NULL,
  type VARCHAR(40) NOT NULL DEFAULT 'general',
  text VARCHAR(500) NOT NULL,
  link VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_recipient FOREIGN KEY (recipient_id) REFERENCES users (id) ON DELETE CASCADE,
  INDEX ix_notifications_recipient (recipient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS notification_reads (
  notification_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  read_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id, user_id),
  CONSTRAINT fk_reads_notification FOREIGN KEY (notification_id) REFERENCES notifications (id) ON DELETE CASCADE,
  CONSTRAINT fk_reads_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_id BIGINT UNSIGNED NULL,
  action VARCHAR(120) NOT NULL,
  target VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_id) REFERENCES users (id) ON DELETE SET NULL,
  INDEX ix_audit_time (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- SECTION 2: DEMO SEED (mirrors frontend/js/seed.js names; runs once on a fresh DB)
-- Re-runs are safe: INSERT IGNORE skips rows whose PK/UNIQUE already exists.
-- ============================================================================
INSERT IGNORE INTO users (id, name, student_id, password_hash, role, suspended, can_upload, can_add_course) VALUES
  (1, 'Administrator', NULL, '$2y$10$demohashplaceholder00000000000000000000000000001', 'admin', FALSE, TRUE, TRUE),
  (2, 'Fahim M.', '0112430687', '$2y$10$demohashplaceholder00000000000000000000000000002', 'student', FALSE, TRUE, FALSE),
  (3, 'Raysa S.', '0112420576', '$2y$10$demohashplaceholder00000000000000000000000000003', 'student', FALSE, TRUE, FALSE),
  (4, 'Sami R.', '0112410312', '$2y$10$demohashplaceholder00000000000000000000000000004', 'student', FALSE, TRUE, FALSE);

INSERT IGNORE INTO courses (id, code, title, semester, created_by) VALUES
  (1, 'CSE 221', 'Data Structures', 'Summer 2026', 1),
  (2, 'CSE 222', 'Database Management Systems', 'Summer 2026', 1),
  (3, 'CSE 321', 'Web Programming', 'Summer 2026', 1);

-- id=3 stays 'pending' for the TRANSACTION demo (approve flow). id=4 is a
-- sacrificial 'rejected' row for the DELETE demo.
INSERT IGNORE INTO resources (id, course_id, title, type, link, version, uploaded_by, status, download_count) VALUES
  (1, 2, 'Normalization 1NF to BCNF Slides', 'Slides', 'https://drive.google.com/demo1', 'v2.0', 3, 'approved', 189),
  (2, 2, 'Past Questions Summer 2024-25', 'Past Questions', 'https://drive.google.com/demo2', 'v1.0', 2, 'approved', 342),
  (3, 2, 'SQL JOIN Practice Sheet', 'Lab Sheet', NULL, 'v1.0', 4, 'pending', 0),
  (4, 1, 'Draft duplicate upload', 'Notes', NULL, 'v1.0', 4, 'rejected', 0);

INSERT IGNORE INTO resource_ratings (resource_id, user_id, stars) VALUES
  (1, 2, 5), (1, 4, 4), (2, 3, 5), (2, 4, 5);

INSERT INTO resource_downloads (resource_id, user_id) VALUES
  (1, 2), (1, 3), (1, 4), (2, 2), (2, 4);

INSERT IGNORE INTO rooms (id, course_id, title, host_id, scheduled_at, capacity, link, status) VALUES
  (1, 2, 'ERD Practice - Lab 2 Prep', 2, '2026-09-21 19:00:00', 8, 'https://meet.link/erd-prep', 'active');

INSERT IGNORE INTO room_members (room_id, user_id) VALUES
  (1, 2), (1, 3), (1, 4);

INSERT IGNORE INTO messages (id, course_id, user_id, body) VALUES
  (1, 2, 3, 'Anyone solved Q3 of normalization sheet?'),
  (2, 2, 2, 'Yes - decompose to 3NF first, then check BCNF dependency.');

INSERT IGNORE INTO message_attachments (id, message_id, kind, file_name, file_url) VALUES
  (1, 2, 'link', 'solution.pdf', 'https://drive.google.com/sol');

INSERT IGNORE INTO reports (id, reporter_id, kind, course_id, resource_id, reason, status) VALUES
  (1, 3, 'resource', 2, 2, 'Possible outdated syllabus version', 'open');

INSERT INTO notifications (recipient_id, type, text, link) VALUES
  (NULL, 'rooms', 'Welcome to UIU Dock - create an account to upload, join rooms and chat.', 'login.html');

INSERT INTO audit_logs (actor_id, action, target) VALUES
  (1, 'Approved resource', 'Normalization 1NF to BCNF Slides (CSE 222)');

-- ============================================================================
-- SECTION 3: INDEX NOTE (written explanation — SQL Coverage: Index)
-- ix_resource_course_status (course_id, status): hub search always filters by
--   course + approval status (resources.html render()), so one composite index
--   serves the WHERE before sorting by downloads/rating.
-- ft_resource_title FULLTEXT: title search via MATCH ... AGAINST instead of
--   LIKE '%...%', which cannot use a B-tree index.
-- ix_messages_course_time (course_id, created_at): chat history is always
--   per-course chronological (help-desk.html renderChat()), newest-last page.
-- ix_rooms_schedule (course_id, scheduled_at): room lists filter by course and
--   order by schedule (rooms.html render()).
-- ix_report_status (status): staff inbox filters open reports first
--   (admin.html reports pane); low-cardinality but combined with small table it
--   keeps the moderation queue scan cheap.
-- ix_download_resource / ix_download_user / ix_attachments_message /
--   ix_notifications_recipient / ix_audit_time: FK join + ORDER BY support for
--   analytics (downloads per resource), chat attachments, bell dropdown, audit trail.
-- ============================================================================

-- ============================================================================
-- SECTION 4: REUSABLE VIEWS (SQL Coverage: View — used by app features)
-- ============================================================================

-- Resource Hub list (resources.html): approved items + course + author +
-- live download events + average rating. Hub search/filters SELECT from here.
CREATE OR REPLACE VIEW v_approved_resources AS
SELECT
  r.id, r.title, r.type, r.link, r.version, r.status,
  r.download_count, r.created_at,
  c.code AS course_code, c.title AS course_title,
  u.name AS author,
  (SELECT COUNT(*) FROM resource_downloads d WHERE d.resource_id = r.id) AS dl_events,
  (SELECT AVG(rt.stars) FROM resource_ratings rt WHERE rt.resource_id = r.id) AS avg_rating
FROM resources r
  INNER JOIN courses c ON c.id = r.course_id
  INNER JOIN users u ON u.id = r.uploaded_by
WHERE r.status = 'approved';

-- Staff overview stats (admin.html renderAll): per-course activity counts.
CREATE OR REPLACE VIEW v_course_activity AS
SELECT
  c.id, c.code, c.title, c.semester,
  (SELECT COUNT(*) FROM resources r WHERE r.course_id = c.id AND r.status = 'approved') AS approved_resources,
  (SELECT COUNT(*) FROM resources r WHERE r.course_id = c.id AND r.status = 'pending') AS pending_resources,
  (SELECT COUNT(*) FROM rooms m WHERE m.course_id = c.id AND m.status = 'active') AS active_rooms,
  (SELECT COUNT(*) FROM messages m WHERE m.course_id = c.id AND m.deleted = FALSE) AS live_messages
FROM courses c;

-- ============================================================================
-- SECTION 5: DML (SQL Coverage: SELECT / INSERT / UPDATE / DELETE)
-- Each statement is labeled with the app feature that runs it.
-- ============================================================================

-- SELECT — Feature: Resource Hub search (resources.html render()).
SELECT id, title, course_code, author, avg_rating, dl_events
FROM v_approved_resources
WHERE course_code = 'CSE 222' AND title LIKE '%JOIN%'
ORDER BY dl_events DESC;

-- SELECT (FULLTEXT) — Feature: Hub keyword search on titles.
SELECT id, title, course_code
FROM v_approved_resources
WHERE MATCH(title) AGAINST ('normalization' IN NATURAL LANGUAGE MODE);

-- INSERT — Feature: student upload, "Submit for Review" (resources.html doUpload()).
-- Creates one 'pending' row per run for the staff moderation queue.
INSERT INTO resources (course_id, title, type, link, version, uploaded_by, status)
VALUES (2, 'Transaction Isolation Notes', 'Notes', 'https://drive.google.com/demo3', 'v1.0', 4, 'pending');

-- UPDATE — Feature: staff approve (admin.html ap()). Also run atomically in Section 8.
UPDATE resources SET status = 'approved' WHERE id = 3 AND status = 'pending';

-- DELETE — Feature: staff remove rejected upload (admin.html askRj()/delRes()).
DELETE FROM resources WHERE id = 4 AND status = 'rejected';

-- ============================================================================
-- SECTION 6: AGGREGATION (SQL Coverage: 2+ aggregate functions, GROUP BY, HAVING)
-- ============================================================================

-- AGG-1 — Feature: admin analytics, top resources by rating + downloads.
-- Uses COUNT + AVG with GROUP BY + HAVING.
SELECT
  r.id, r.title,
  COUNT(DISTINCT d.id) AS downloads,
  AVG(rt.stars) AS avg_stars
FROM resources r
  LEFT JOIN resource_downloads d ON d.resource_id = r.id
  LEFT JOIN resource_ratings rt ON rt.resource_id = r.id
WHERE r.status = 'approved'
GROUP BY r.id, r.title
HAVING AVG(rt.stars) >= 4.5 AND COUNT(DISTINCT d.id) >= 1
ORDER BY avg_stars DESC, downloads DESC;

-- AGG-2 — Feature: admin analytics, download volume per course.
-- Uses COUNT + SUM + MAX with GROUP BY + HAVING.
SELECT
  c.code,
  COUNT(d.id) AS dl_events,
  SUM(r.download_count) AS cached_total,
  MAX(r.download_count) AS top_resource_downloads
FROM courses c
  INNER JOIN resources r ON r.course_id = c.id
  LEFT JOIN resource_downloads d ON d.resource_id = r.id
GROUP BY c.code
HAVING COUNT(d.id) >= 1
ORDER BY dl_events DESC;

-- ============================================================================
-- SECTION 7: JOINS + SUBQUERY (SQL Coverage)
-- ============================================================================

-- INNER JOIN — Feature: published hub list with course + author (resources.html).
SELECT r.title, c.code AS course, u.name AS author, r.download_count
FROM resources r
  INNER JOIN courses c ON c.id = r.course_id
  INNER JOIN users u ON u.id = r.uploaded_by
WHERE r.status = 'approved'
ORDER BY r.download_count DESC;

-- LEFT JOIN — Feature: course catalog with usage, including empty courses
-- (admin.html courseRows shows "in use" vs removable).
SELECT c.code, c.title, COUNT(r.id) AS resource_count
FROM courses c
  LEFT JOIN resources r ON r.course_id = c.id AND r.status = 'approved'
GROUP BY c.id, c.code, c.title
ORDER BY c.code;

-- CORRELATED SUBQUERY — Feature: "above-average for its listing" highlight:
-- approved resources rated above the global average rating.
SELECT r.id, r.title,
  (SELECT AVG(rt2.stars) FROM resource_ratings rt2 WHERE rt2.resource_id = r.id) AS avg_rating
FROM resources r
WHERE r.status = 'approved'
  AND (SELECT AVG(rt2.stars) FROM resource_ratings rt2 WHERE rt2.resource_id = r.id)
      > (SELECT AVG(stars) FROM resource_ratings);

-- ============================================================================
-- SECTION 8: TRANSACTION (SQL Coverage: BEGIN / COMMIT / ROLLBACK)
-- Feature: staff approve flow (admin.html ap()) — status change + audit trail +
-- uploader notification must all succeed or all fail together.
-- ============================================================================
BEGIN;
UPDATE resources SET status = 'approved' WHERE id = 3 AND status = 'pending';
INSERT INTO audit_logs (actor_id, action, target)
VALUES (1, 'Approved resource', 'SQL JOIN Practice Sheet (CSE 222)');
INSERT INTO notifications (recipient_id, type, text, link)
VALUES (4, 'uploads', 'Approved: "SQL JOIN Practice Sheet" is now live in CSE 222', 'resources.html');
COMMIT;

-- ROLLBACK demo — Feature: staff dismisses a compose by mistake; nothing persists.
BEGIN;
INSERT INTO notifications (recipient_id, type, text, link)
VALUES (2, 'general', 'Draft notice (rolled back, never delivered)', 'index.html');
ROLLBACK;
