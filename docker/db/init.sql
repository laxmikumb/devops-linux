CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL
);

INSERT INTO products (name, price) VALUES
  ('Notebook', 4.50),
  ('Pen Set', 3.25),
  ('Backpack', 29.99),
  ('Water Bottle', 8.75),
  ('Desk Lamp', 15.00);
