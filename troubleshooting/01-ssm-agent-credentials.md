# Incident 01 — EC2 instance won't connect via SSM Session Manager

## Symptom
Attempting to connect to the private EC2 app server (`guestbook-app`) through
**SSM Session Manager** failed. On the Connect screen:
- **Ping status:** blank (`-`)
- **SSM agent version:** blank (`-`)
- **Session Manager connection status:** Not connected

Latest error message from the agent:
```
SSM Agent unable to acquire credentials: no valid credentials could be retrieved
for ec2 identity. Default Host Management Err: error calling
RequestManagedInstanceRoleToken: AccessDeniedException: Systems Manager's
instance management role is not configured for account
```

## What the symptom told me
Blank Ping status and agent version meant the instance had **never successfully
registered** with Systems Manager — this wasn't a dropped session, it had never
connected at all. The agent reported it could not acquire credentials for the EC2
identity and was falling back to "Default Host Management" (a separate mechanism),
which also wasn't configured — so the fallback error was a red herring. The real
issue was that the agent wasn't getting credentials from the instance's IAM role.

## Hypotheses (in the order I checked them)
1. The IAM role was missing the required SSM permissions.
2. The instance profile wasn't actually attached.
3. The role's **trust policy** didn't allow EC2 to assume it (so the instance
   couldn't obtain credentials at all).
4. The role was attached *after* launch and the agent hadn't picked it up.

## Diagnosis
- Confirmed `AmazonSSMManagedInstanceCore` was attached to `guestbook-ec2-role`
  (permissions were fine — ruled out #1).
- Confirmed the instance profile was attached to the instance (ruled out #2).
- Checked the role's **Trust relationships** tab.
  The trust policy governs *who can assume the role*. The error "no valid credentials
  could be retrieved for ec2 identity" points at exactly this: if the trusted
  principal isn't `ec2.amazonaws.com`, the instance cannot assume the role and gets
  no credentials.

## Root cause
The IAM role was not correctly trusted by the EC2 service (and the role had been
attached after the instance was already running, so the agent had not re-read
credentials). With no assumable role, the SSM agent had no credentials to register
with Systems Manager.

## Fix
1. Ensured the role's trust policy allowed the EC2 service:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": { "Service": "ec2.amazonaws.com" },
       "Action": "sts:AssumeRole"
     }]
   }
   ```
2. Confirmed `AmazonSSMManagedInstanceCore` was attached.
3. Rebooted the instance so the SSM agent re-read the instance-profile credentials.
4. Waited ~2 minutes; Ping status changed to **Online** and Session Manager connected.

## Prevention / what I'd tell a customer
- When creating an EC2 role, create it via **IAM → Create role → AWS service → EC2**
  so the trust policy is correct from the start.
- Attach the instance role **at launch** rather than after, to avoid the agent
  needing a restart to pick up credentials.

