import os
from flask import Flask, jsonify, request
import psycopg2
import psycopg2.extras
import requests as http

app = Flask(__name__)

DB_HOST = os.getenv("POSTGRES_HOST", "postgres")
DB_PORT = int(os.getenv("POSTGRES_PORT", "5432"))
DB_NAME = os.getenv("POSTGRES_DB", "app")
DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "postgres")

LOGGER_URL = os.getenv("LOGGER_URL", "http://logger:6000/log")


def get_conn():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
    )


def run_migrations():
    ddl = """
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(ddl)
    except Exception as e:
        app.logger.error(f"Migration failed: {e}")


_MIGRATIONS_RAN = False


@app.before_request
def ensure_migrations():
    global _MIGRATIONS_RAN
    if not _MIGRATIONS_RAN:
        try:
            run_migrations()
        finally:
            _MIGRATIONS_RAN = True


@app.after_request
def log_request(response):
    try:
        payload = {
            "service": "backend",
            "method": request.method,
            "path": request.path,
            "status": response.status_code,
        }
        # Fire-and-forget logging; do not block response
        http.post(LOGGER_URL, json=payload, timeout=0.5)
    except Exception:
        pass
    return response


@app.route("/api/data")
def get_data():
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM users")
                (count,) = cur.fetchone()
        return jsonify({"message": "Hello from backend", "status": "ok", "users_count": count})
    except Exception as e:
        return jsonify({"message": "Backend error", "error": str(e)}), 500


@app.route("/api/users", methods=["GET"])
def list_users():
    try:
        with get_conn() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute("SELECT id, name, created_at FROM users ORDER BY id DESC LIMIT 100")
                rows = cur.fetchall()
        return jsonify({"users": rows})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/users", methods=["POST"])
def create_user():
    body = request.get_json(silent=True) or {}
    name = (body.get("name") or "").strip()
    if not name:
        return jsonify({"error": "name is required"}), 400
    try:
        with get_conn() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute("INSERT INTO users(name) VALUES (%s) RETURNING id, name, created_at", (name,))
                row = cur.fetchone()
        return jsonify(row), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/")
def root():
    return jsonify({"service": "backend", "health": "ok"})


if __name__ == "__main__":
    # Run migrations on dev server startup
    run_migrations()
    app.run(host="0.0.0.0", port=5000, debug=True)
