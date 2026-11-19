import os
import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)


def get_conn():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
    )


@app.route("/api/health")
def health():
    return "OK", 200


@app.route("/api/products")
def products():
    conn = get_conn()
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, name, price FROM products ORDER BY id")
        rows = [{"id": r[0], "name": r[1], "price": float(r[2])} for r in cur.fetchall()]
        return jsonify(rows)
    finally:
        conn.close()
