"""
Simple three-tier demo app: a guestbook.

Web tier (ALB) -> App tier (this Flask app on EC2) -> Data tier (RDS MySQL).

Design choices that map to the troubleshooting scenarios:
  - Reads the DB password from AWS Secrets Manager.
  - Exposes /health for the ALB target group health check.
  - Every page load / post touches RDS.
"""

import os
import json
import pymysql
import boto3
from botocore.exceptions import ClientError
from flask import Flask, request, redirect, render_template_string

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_NAME = os.environ.get("DB_NAME", "guestbook")
DB_USER = os.environ.get("DB_USER", "admin")
DB_SECRET_ID = os.environ.get("DB_SECRET_ID")
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")


def get_db_password():
    """
    Fetch the DB password from Secrets Manager.
    """
    if not DB_SECRET_ID:
        return os.environ.get("DB_PASSWORD", "")

    client = boto3.client("secretsmanager", region_name=AWS_REGION)
    try:
        resp = client.get_secret_value(SecretId=DB_SECRET_ID)
    except ClientError as e:
        app.logger.error("Secrets Manager error: %s", e)
        raise

    secret = resp["SecretString"]
    try:
        return json.loads(secret)["password"]
    except (ValueError, KeyError):
        return secret


def get_connection():
    """Open a short-lived connection to RDS. Times out if the DB SG blocks us."""
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=get_db_password(),
        database=DB_NAME,
        connect_timeout=5,
        cursorclass=pymysql.cursors.DictCursor,
    )


def init_db():
    """Create the messages table if it doesn't exist. Run once on startup."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS messages (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(100) NOT NULL,
                    body VARCHAR(500) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        conn.commit()
    finally:
        conn.close()


PAGE = """
<!doctype html>
<html>
<head>
  <title>Guestbook</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 640px; margin: 40px auto; padding: 0 16px; }
    h1 { margin-bottom: 4px; }
    .sub { color: #666; margin-top: 0; }
    form { margin: 24px 0; }
    input, textarea { width: 100%; padding: 8px; margin: 6px 0; box-sizing: border-box; }
    button { padding: 8px 16px; cursor: pointer; }
    .msg { border-top: 1px solid #eee; padding: 12px 0; }
    .meta { color: #888; font-size: 0.85em; }
  </style>
</head>
<body>
  <h1>Guestbook</h1>
  <p class="sub">Three-tier AWS demo: ALB &rarr; EC2 (Flask) &rarr; RDS (MySQL)</p>

  <form method="POST" action="/post">
    <input name="name" placeholder="Your name" maxlength="100" required>
    <textarea name="body" placeholder="Leave a message" maxlength="500" required></textarea>
    <button type="submit">Sign guestbook</button>
  </form>

  {% for m in messages %}
    <div class="msg">
      <strong>{{ m.name }}</strong>
      <div>{{ m.body }}</div>
      <div class="meta">{{ m.created_at }}</div>
    </div>
  {% else %}
    <p>No messages yet. Be the first!</p>
  {% endfor %}
</body>
</html>
"""


@app.route("/")
def index():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT name, body, created_at FROM messages ORDER BY id DESC LIMIT 50")
            messages = cur.fetchall()
    finally:
        conn.close()
    return render_template_string(PAGE, messages=messages)


@app.route("/post", methods=["POST"])
def post():
    name = request.form.get("name", "").strip()
    body = request.form.get("body", "").strip()
    if name and body:
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO messages (name, body) VALUES (%s, %s)",
                    (name, body),
                )
            conn.commit()
        finally:
            conn.close()
    return redirect("/")


@app.route("/health")
def health():
    """
    Health check for ALB 
    ALB target group health check hits this.
    """
    try:
        conn = get_connection()
        conn.close()
        return "ok", 200
    except Exception as e:
        app.logger.error("Health check failed: %s", e)
        return "unhealthy", 503

try:
    init_db()
except Exception as e:
    app.logger.error("init_db failed at startup (is RDS reachable?): %s", e)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)