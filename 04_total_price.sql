-- =====================================================================
-- Migration 04
-- =====================================================================

PRAGMA foreign_keys = OFF;

BEGIN;

DROP TABLE IF EXISTS orders_new;

CREATE TABLE orders_new (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id           INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at        TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retrieval_date    TEXT    NOT NULL CHECK (datetime(retrieval_date) IS NOT NULL),
    status            TEXT    NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending', 'ready', 'done', 'cancelled')),
    total_price_cents INTEGER NOT NULL DEFAULT 0 CHECK (total_price_cents >= 0)
);

-- Recalculating the total price for existing orders
INSERT INTO orders_new (id, user_id, created_at, retrieval_date, status, total_price_cents)
SELECT o.id, o.user_id, o.created_at, o.retrieval_date, o.status,
       COALESCE((SELECT SUM(op.quantity * p.price_cents)
                   FROM order_products op
                   JOIN products p ON p.id = op.product_id
                  WHERE op.order_id = o.id), 0)
     + COALESCE((SELECT SUM(om.quantity * m.price_cents)
                   FROM order_menus om
                   JOIN menus m ON m.id = om.menu_id
                  WHERE om.order_id = o.id), 0)
FROM orders o;

-- Recovering the autoincrement index
DELETE FROM sqlite_sequence WHERE name = 'orders_new';
INSERT INTO sqlite_sequence (name, seq)
SELECT 'orders_new', seq FROM sqlite_sequence WHERE name = 'orders';

DROP TABLE orders;
ALTER TABLE orders_new RENAME TO orders;

CREATE INDEX idx_orders_user      ON orders(user_id);
CREATE INDEX idx_orders_retrieval ON orders(retrieval_date);

PRAGMA foreign_key_check;

COMMIT;

PRAGMA foreign_keys = ON;
