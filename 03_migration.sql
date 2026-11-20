-- =====================================================================
-- Migration 03
-- =====================================================================

PRAGMA foreign_keys = OFF;

BEGIN;

------------------------------------------------------------------------

DROP TABLE IF EXISTS orders_new;

CREATE TABLE orders_new (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id        INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at     TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retrieval_date TEXT    NOT NULL CHECK (datetime(retrieval_date) IS NOT NULL),
    status         TEXT    NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'ready', 'done'))
);

INSERT INTO orders_new (id, user_id, created_at, retrieval_date, status)
SELECT id, user_id, created_at, retrieval_date, status FROM orders;

-- Recovers the autoincrement value
DELETE FROM sqlite_sequence WHERE name = 'orders_new';
INSERT INTO sqlite_sequence (name, seq)
SELECT 'orders_new', seq FROM sqlite_sequence WHERE name = 'orders';

DROP TABLE orders;
ALTER TABLE orders_new RENAME TO orders;

CREATE INDEX idx_orders_user      ON orders(user_id);
CREATE INDEX idx_orders_retrieval ON orders(retrieval_date);

------------------------------------------------------------------------

DROP TABLE IF EXISTS menus_new;

CREATE TABLE menus_new (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT    NOT NULL CHECK (length(name) >= 1),
    is_available  INTEGER NOT NULL DEFAULT 1 CHECK (is_available IN (0, 1)),
    is_deleted    INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
    starting_date TEXT    CHECK (starting_date IS NULL OR datetime(starting_date) IS NOT NULL),
    ending_date   TEXT    CHECK (ending_date   IS NULL OR datetime(ending_date)   IS NOT NULL),
    price_cents   INTEGER NOT NULL CHECK (price_cents >= 0),
    CHECK (starting_date IS NULL OR ending_date IS NULL OR ending_date >= starting_date)
);

INSERT INTO menus_new (id, name, is_available, is_deleted, starting_date, ending_date, price_cents)
SELECT id, name, is_available, is_deleted, starting_date, ending_date, price_cents FROM menus;

DELETE FROM sqlite_sequence WHERE name = 'menus_new';
INSERT INTO sqlite_sequence (name, seq)
SELECT 'menus_new', seq FROM sqlite_sequence WHERE name = 'menus';

DROP TABLE menus;
ALTER TABLE menus_new RENAME TO menus;

CREATE UNIQUE INDEX idx_menus_name_active
    ON menus(name);

PRAGMA foreign_key_check;

COMMIT;

PRAGMA foreign_keys = ON;
