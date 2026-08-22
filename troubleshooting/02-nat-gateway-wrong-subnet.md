# Incident 02 — SSM connection times out after recreating the NAT Gateway

## Context
To control cost overnight, I deleted the NAT Gateway and stopped the EC2/RDS
instances. The next day I recreated the NAT Gateway and restarted the instances,
then tried to reconnect via SSM Session Manager.

## Symptom
Session Manager would not connect. Ping status blank, and the SSM agent reported:
```
SSM Agent unable to acquire credentials: unexpected error getting instance profile
role credentials or calling UpdateInstanceInformation ... send request failed
caused by: Post "https://ssm.us-east-1.amazonaws.com/": dial tcp 44.216.199.76:443:
i/o timeout
```

## What the symptom told me
This was a **network timeout**, not a credentials error (unlike Incident 01 — the
agent now had its credentials). The agent was trying to reach the public SSM endpoint
`ssm.us-east-1.amazonaws.com` on port 443 and the connection timed out. A timeout to
a public AWS endpoint from a private instance means the instance has **no working
outbound path to the internet** — i.e. the NAT path was broken.

## Hypotheses (in order)
1. The private subnet's route table `0.0.0.0/0` route wasn't pointing at the new NAT
   (still a blackhole from the deleted NAT).
2. I edited the wrong route table (not the one associated with the instance's subnet).
3. The NAT Gateway itself couldn't reach the internet — i.e. it was placed in a
   subnet without a route to the Internet Gateway.

## Diagnosis
- Verified the instance's subnet and traced it to its associated route table.
- Inspected the NAT Gateway's own subnet and its route table. This is where I found
  the problem: **the NAT Gateway had been created in a private subnet.** A NAT
  Gateway must live in a *public* subnet (one with a `0.0.0.0/0 → igw-...` route) so
  that it can egress to the internet. Placed in a private subnet, the NAT had no path
  out, so every request routed through it — including the agent's call to the SSM
  endpoint — timed out.

## Root cause
The NAT Gateway was deployed into a **private** subnet instead of a public one. The
NAT therefore had no route to the Internet Gateway and could not provide outbound
connectivity, causing i/o timeouts for anything behind it.

## Fix
NAT Gateways cannot be moved between subnets, so:
1. Deleted the misplaced NAT Gateway.
2. Released/relocated its Elastic IP.
3. Created a new NAT Gateway in a **public** subnet (verified the subnet's route table
   contained a `0.0.0.0/0 → igw-...` entry before choosing it).
4. Updated the **private** subnet's route table so `0.0.0.0/0` pointed at the new NAT
   (replacing the blackhole route).
5. Waited ~2 minutes; the SSM agent retried automatically (no reboot needed) and Ping
   status went **Online**. Confirmed outbound with `curl -I https://aws.amazon.com`.

## Prevention / what I'd tell a customer
- Before creating a NAT Gateway, confirm the target subnet is **public** by checking
  its route table for the Internet Gateway route. "NAT in a private subnet" is a
  classic, silent misconfiguration — it creates successfully and only fails at traffic
  time.
- Distinguish the two roles clearly: the NAT *lives in* a public subnet but *serves*
  the private subnets. The public subnet needs the IGW route; the private subnet needs
  the NAT route.
- After recreating a NAT, always re-check the private route table — deleting a NAT
  leaves the old route as a "blackhole" that must be repointed.
- Diagnostic shortcut: a timeout to a public AWS endpoint (`ssm`, `s3`, etc.) from a
  private instance is almost always a NAT/route problem, not the service itself.
  `curl -I https://aws.amazon.com` from the instance isolates it in one command.
