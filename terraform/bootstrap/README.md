# Bootstrap

This tiny, separate Terraform config solves the "chicken and egg" problem of
remote state:

> To store state remotely in S3, you need an S3 bucket. But Terraform normally
> stores state for the resources *it* creates... including that bucket.

You can't configure a backend that points at a bucket that doesn't exist yet.
So this directory is deliberately **not** part of the main project and
deliberately uses **local** state (there's no `backend` block below). You run
it exactly once (per AWS account/region you use), it creates:

- An S3 bucket to hold the real project's `.tfstate`, with versioning
  (so a bad apply's state can be rolled back) and encryption enabled.
- A DynamoDB table used for **state locking** - it stops two people (or you,
  in two terminals) from running `terraform apply` at the same time and
  corrupting the state file.

After this runs once, you never touch it again. Its own `terraform.tfstate`
file (a handful of KB, just describing the bucket and table) is safe to keep
local or even commit - unlike the main project's state, it holds no
application secrets.

## Usage

```bash
cd bootstrap
terraform init
terraform apply
# copy the two outputs (bucket name + dynamodb table name) into
# ../environments/dev/backend.tf
```
