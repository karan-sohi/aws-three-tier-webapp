# Incident 03 — App can't reach the database after an instance reboot

## Context
After stopping the EC2 instance overnight and starting it again the next day, I
reconnected via SSM and started the Flask app with `python3 app.py`. It failed to
serve requests.

## Symptom
The app started but every request failed. Logs showed:
```
ERROR in app: init_db failed (is RDS reachable?): (2003, "Can't connect to MySQL
server on 'localhost' ([Errno 111] Connection refused)")
...
GET /health HTTP/1.1" 503
...
ConnectionRefusedError: [Errno 111] Connection refused
  File ".../app.py", line 51, in get_connection
    return pymysql.connect(...)
```
The `/health` endpoint returned 503 and the index page threw a 500. From the outside,
browsing to the **ALB DNS name returned "Internal Server Error"** — the same failure
seen through the load balancer: the ALB forwarded the request to the app, the app
couldn't reach its database, and returned a 500. (The ALB target also flipped to
**unhealthy**, because `/health` was returning 503.)

## What the symptom told me
The critical detail was the host in the error: **`localhost`**. The app was trying to
connect to a MySQL server on the instance itself, not to the RDS endpoint. RDS is a
remote managed database — the app should never be pointing at localhost. So this was
not a networking or RDS problem; the app was using the **wrong database host**, which
meant its configuration wasn't set.

## Hypotheses (in order)
1. RDS was down or unreachable (network / security group).
2. The app was misconfigured and pointing at the wrong host.

I ruled out #1 immediately: if it were a network/SG issue, the error would show the
*RDS endpoint* timing out, not `localhost` refusing the connection. `localhost` +
"Connection refused" means the app resolved its DB host to localhost — a config
problem.

## Root cause
Environment variables set in the shell with `export` (`DB_HOST`, `DB_NAME`,
`DB_USER`, `DB_SECRET_ID`, etc.) **do not persist across a reboot or a new shell
session.** After the instance restarted, those variables were gone. The application
code falls back to a default of `localhost` when `DB_HOST` is unset, so it tried to
connect to a database on the instance itself — where nothing is listening — and got
"Connection refused."

## Fix
Re-declared the environment variables in the shell before launching the app:
```bash
export DB_HOST="guestbook-db.xxxx.us-east-1.rds.amazonaws.com"
export DB_NAME="guestbook"
export DB_USER="admin"
export DB_SECRET_ID="guestbook/db"
export AWS_REGION="us-east-1"
python3 app.py
```
With `DB_HOST` correctly set, the app connected to RDS and `/health` returned 200.

## Prevention / what I'd tell a customer
- Shell `export` variables are session-scoped and are lost on logout/reboot. For a
  service that must survive restarts, define configuration in a persistent location.
- The proper fix is to run the app as a **systemd service** with the variables baked
  into the unit file (or an `EnvironmentFile`), e.g.:
  ```ini
  [Service]
  Environment=DB_HOST=guestbook-db.xxxx.us-east-1.rds.amazonaws.com
  Environment=DB_NAME=guestbook
  Environment=DB_SECRET_ID=guestbook/db
  Environment=AWS_REGION=us-east-1
  ExecStart=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:8080 app:app
  Restart=always
  ```
  systemd re-reads these on every start, so the app comes back correctly after a
  reboot with no manual steps.
- Diagnostic takeaway: when a DB connection error names **`localhost`** unexpectedly,
  suspect missing/*unset configuration* (falling back to a default), not the database
  or the network. The host in the error message tells you where the app *thinks* the
  database is.
