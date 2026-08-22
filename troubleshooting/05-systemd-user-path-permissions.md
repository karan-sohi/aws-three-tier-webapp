# Incident 05 — Deploying as a systemd service: a cascade of user, path, and permission errors

## Context
To make the app survive reboots and stop losing environment variables (see Incident
03), I moved from running `python3 app.py` by hand to running it under **gunicorn**
managed by a **systemd** service. Getting the service to boot took working through
three related failures — all rooted in the same underlying issue.

## Failure 1 — `ModuleNotFoundError: No module named 'app'`
### Symptom
Running gunicorn manually:
```
/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:8080 app:app
...
ModuleNotFoundError: No module named 'app'
Reason: Worker failed to boot.
```
### Diagnosis / root cause
`app:app` tells gunicorn to import the module `app` (i.e. `app.py`) and use the `app`
object inside it. Gunicorn resolves the module against its **current working
directory**. The command was run from a directory that did not contain `app.py`, so
the import failed.
### Fix
Run gunicorn from the directory containing `app.py` (or set `WorkingDirectory` in the
unit file so systemd changes into it automatically):
```bash
cd ~/guestbook/aws-three-tier-webapp
gunicorn -w 2 -b 0.0.0.0:8080 app:app
```

## Failure 2 — `CHDIR ... Permission denied` under systemd
### Symptom
After creating the service, `journalctl -u guestbook` showed:
```
guestbook.service: Changing to the requested working directory failed: Permission denied
guestbook.service: Failed at step CHDIR spawning /usr/local/bin/gunicorn: Permission denied
```
### Diagnosis
`CHDIR` = "change directory." systemd started the service as `User=ec2-user`, then
tried to `cd` into the configured `WorkingDirectory` and was denied. The app and its
Python packages actually lived under **`/home/ssm-user/`** (all prior work was done as
`ssm-user`), but the service was configured to run as **`ec2-user`**. A Linux home
directory is permission-locked (mode 700) to its owner, so `ec2-user` cannot enter
`ssm-user`'s home — hence "Permission denied."

## Root cause (the common thread)
The code and the pip packages were installed in **one user's home** (`ssm-user`, via
per-user `pip install`), while the systemd service ran as a **different user**
(`ec2-user`). That single mismatch produced both the CHDIR permission error (can't
access the directory) and would have produced a `ModuleNotFoundError` for Flask/pymysql
(can't see another user's `.local` packages) even after fixing the path.

## Fix
Aligned the user, the file location, and the package installation:
1. Relocated the app to a directory the service user owns:
   ```bash
   sudo mkdir -p /home/ec2-user/guestbook
   sudo cp -r /home/ssm-user/guestbook/aws-three-tier-webapp /home/ec2-user/guestbook/
   sudo chown -R ec2-user:ec2-user /home/ec2-user/guestbook
   ```
2. Installed dependencies **system-wide** so any user (including the service user) can
   import them — instead of a per-user install hidden in one home directory:
   ```bash
   sudo pip3 install -r requirements.txt gunicorn
   ```
3. Set the unit file so `User`, `WorkingDirectory`, and `ExecStart` all agree:
   ```ini
   [Service]
   User=ec2-user
   WorkingDirectory=/home/ec2-user/guestbook/aws-three-tier-webapp
   ExecStart=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:8080 app:app
   ```
4. `sudo systemctl daemon-reload && sudo systemctl restart guestbook`, then verified
   with `systemctl status guestbook` (active/running) and `curl -i localhost:8080/health`.

## Note — sudo is NOT the fix
A tempting but wrong instinct was to add `sudo` to the service. A systemd service already
starts as root and intentionally drops to the unprivileged `User=` for security; you
don't `sudo` inside a unit. The correct fix is to make the service user genuinely able
to reach its files and packages.

## Prevention / what I'd tell a customer
- A service must run as a user that both **owns/can access the working directory** and
  **can see the Python packages**. Keep app code and dependencies out of a single
  user's home when a service will run as someone else.
- Prefer **system-wide** (or a dedicated virtualenv) dependency installs for services —
  per-user `pip install` puts packages in `~/.local`, invisible to other users.
- `CHDIR ... Permission denied` in a unit almost always means a `User`/`WorkingDirectory`
  ownership mismatch, not a need for elevated privileges.
- The gunicorn target `module:variable` (`app:app`) resolves against the working
  directory — set `WorkingDirectory` correctly or the import fails before the app even
  starts.
