# Troubleshooting Log

Real issues encountered while building and operating this three-tier environment,
documented as incident writeups. Each follows the same structure a support engineer
uses on a real ticket: symptom → hypotheses → diagnosis → root cause → fix →
prevention.

These were not scripted — they are actual problems hit during the build, diagnosed
from the error messages and AWS console, and resolved.

Incidents:
1. [SSM Session Manager — instance won't connect (credential failure)](./01-ssm-agent-credentials.md)
2. [SSM Session Manager — connection times out after NAT recreate](./02-nat-gateway-wrong-subnet.md)
3. [App can't reach the database after an instance reboot (lost env vars)](./03-env-vars-lost-after-reboot.md)
4. [CloudWatch alarm never fires despite the app being down (threshold off-by-one)](./04-alarm-threshold-off-by-one.md)
5. [Deploying as a systemd service — user, path, and permission cascade](./05-systemd-user-path-permissions.md)
4. [CloudWatch alarm never fires despite the app being down (threshold off-by-one)](./04-alarm-threshold-off-by-one.md)
