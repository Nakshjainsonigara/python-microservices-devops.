import os
from flask import Flask, request, jsonify

LOG_DIR = os.getenv("LOG_DIR", "/logs")
LOG_FILE = os.path.join(LOG_DIR, os.getenv("LOG_FILE", "requests.log"))

app = Flask(__name__)


def ensure_log_path():
    os.makedirs(LOG_DIR, exist_ok=True)


@app.route("/health")
def health():
    return jsonify({"service": "logger", "health": "ok"})


@app.route("/log", methods=["POST"])
def log_message():
    ensure_log_path()
    payload = request.get_json(silent=True) or {"raw": request.data.decode("utf-8", errors="ignore")}
    line = payload if isinstance(payload, str) else str(payload)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")
    return jsonify({"status": "logged"})


if __name__ == "__main__":
    ensure_log_path()
    app.run(host="0.0.0.0", port=6000, debug=True)

