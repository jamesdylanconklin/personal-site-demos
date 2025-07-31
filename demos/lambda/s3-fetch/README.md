# S3-Fetch

Simple lambda to return objects from a private S3 bucket, intended to eventually be adapted to a simple publish-your-own-blog affair with static assets deployed by Hugo or Jekyll to a designated blog bucket.

## Implementation

This will comprise a NodeJS lambda fetching requested objects from a configured, private S3 bucket. We will define a Terraform module responsible for deploying the lambda, provisioning the S3 bucket, placing a few demo objects inside said bucket, creating API Gateway Resource, Integration, and Method resources, and creating the permissions for a provided API Gateway to use the lambda and for the lambda to access the S3 bucket.

### Paths

| Path | Result |
|------|--------|
| `/demos/fetch/{key}` | Retrieve specified object from S3, or return 403 on miss |
