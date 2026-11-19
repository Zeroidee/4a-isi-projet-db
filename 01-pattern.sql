-- =====================================================================
-- Pol-eat-heck
-- =====================================================================

PRAGMA foreign_keys = ON;

------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    name     TEXT    NOT NULL UNIQUE COLLATE NOCASE
                     CHECK (length(name) BETWEEN 1 AND 32),
    role     TEXT    NOT NULL DEFAULT 'user'
                     CHECK (role IN ('user', 'admin')),
    status   TEXT    NOT NULL DEFAULT 'active'
                     CHECK (status IN ('active', 'blocked')),
    password TEXT    NOT NULL
);

------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS products (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL UNIQUE CHECK (length(name) >= 1),
    is_deleted  INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
    stock       INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0)   -- 450 = 4,50€
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_products_name ON products(name);

------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS menus (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT UNIQUE NOT NULL CHECK (length(name) >= 1),
    is_available  INTEGER NOT NULL DEFAULT 1 CHECK (is_available IN (0, 1)),
    is_deleted    INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
    starting_date TEXT    NOT NULL CHECK (datetime(starting_date) IS NOT NULL),
    ending_date   TEXT    NOT NULL CHECK (datetime(ending_date)   IS NOT NULL),
    price_cents   INTEGER NOT NULL CHECK (price_cents >= 0),
    CHECK (ending_date >= starting_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_menus_name ON menus(name);

--Menu lines : product
CREATE TABLE IF NOT EXISTS menu_products (
    menu_id    INTEGER NOT NULL REFERENCES menus(id)    ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity   INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    PRIMARY KEY (menu_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_menu_products_product ON menu_products(product_id);

------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS closed_days (
    id  INTEGER PRIMARY KEY AUTOINCREMENT,
    day TEXT    NOT NULL UNIQUE
                CHECK (date(day) IS NOT NULL AND date(day) = day)   -- YYYY-MM-DD
);

------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS orders (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id        INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at     TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retrieval_date TEXT    NOT NULL CHECK (datetime(retrieval_date) IS NOT NULL),
    status         TEXT    NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'ready'))
);

CREATE INDEX IF NOT EXISTS idx_orders_user      ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_retrieval ON orders(retrieval_date);

-- Order lines : product
CREATE TABLE IF NOT EXISTS order_products (
    order_id   INTEGER NOT NULL REFERENCES orders(id)   ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity   INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_order_products_product ON order_products(product_id);

-- Order lines : menus
CREATE TABLE IF NOT EXISTS order_menus (
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    menu_id  INTEGER NOT NULL REFERENCES menus(id)  ON DELETE RESTRICT,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    PRIMARY KEY (order_id, menu_id)
);

CREATE INDEX IF NOT EXISTS idx_order_menus_menu ON order_menus(menu_id);
