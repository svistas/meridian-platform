# Session runtime (path 02)

The cluster path 02 deploys to. Everything here is billed by the hour, so it
exists only while someone is working (ADR-0006). A human brings it up and down
locally; CI never creates or destroys it.

```sh
make session-up      # about 15 minutes
make kubeconfig
# ... work ...
make session-down    # destroys, then checks nothing is left billing
```

## What a session costs

eu-west-1 list prices, read from the AWS Pricing API:

| | Per hour |
|---|---|
| EKS control plane | 0.100 |
| NAT gateway | 0.048 (plus data processed) |
| Elastic IP, in use | 0.005 |
| 2 nodes, **spot** | 0.017 – 0.059 |
| **Total** | **0.170 – 0.212** |

The node line is a range because the group may choose any of four types,
depending on which spot pool has capacity:

| Type | Spot, per node | On demand |
|---|---|---|
| `t4g.small` | 0.0085 | 0.0184 |
| `t4g.medium` | 0.0178 | 0.0368 |
| `m6g.medium` | 0.0163 | 0.0430 |
| `m7g.medium` | 0.0292 | 0.0455 |

So **USD 1.36 to 1.70 for an eight-hour day**, and near zero between sessions.
The worst case is about four cents an hour more than the best, which is a
price worth paying not to have a session fail because one spot pool is short.

The daily budget of USD 5 would fire after roughly 24 to 29 hours — the
morning after a session was left running overnight.

Not included: data processed by the NAT gateway, CloudWatch log ingestion, and
the EBS volumes attached to nodes. All small, none hourly in the way the
cluster is.

## Why this is a separate Terraform root

The bootstrap holds what should always exist and costs almost nothing: the
state bucket, the KMS key, the VPC and its private subnets. This root holds
what costs money while it runs. Keeping them apart is what makes
`make session-down` safe to run at any time: it cannot take the KMS key or the
state bucket with it.

The bootstrap's private subnets have no route to the internet. A session adds
one — an internet gateway, a public subnet holding only a NAT gateway, and a
route table the private subnets are associated with for the duration. When the
session ends the association goes and the subnets are sealed again.

## Where the two paths meet

Through a membership group, not by editing each other's resources.

The bootstrap owns a security group called `meridian-datastore-clients`. It
has no rules and never will; it exists only to be a name both paths can point
at. Path 01 writes one rule on each database — *accept Postgres from members
of that group* — and path 01 is the only thing that ever touches it. Path 02
puts its nodes in the group, through the launch template, and that is the
whole of the connection.

While a session is up the group has members and the databases are reachable.
When the session ends the nodes are gone, the group is empty, and the
databases accept nothing again — without anyone having edited a rule.

An earlier version had the session stack add an ingress rule to each
datastore's security group on the way up. It worked, but it meant one path
reaching into another path's resources, and a failed teardown would leave a
rule behind on a database that outlives the session.

## `make session-down` and the check

`terraform destroy` only reports on what Terraform owns. The check that runs
afterwards asks AWS directly, so it also catches what Terraform does not know
about — most likely a load balancer created by a Kubernetes `Service` of type
`LoadBalancer`, which Terraform never saw.

It covers EKS clusters, EC2 instances, NAT gateways, load balancers (both
kinds) and Elastic IPs, and **exits non-zero if any remain**, so the target
fails rather than printing a warning. It runs even when `destroy` fails, which
is exactly the case where something is left behind.

```sh
make check    # same check, without destroying anything
```

It deliberately does not flag storage (EBS, S3, RDS snapshots) or the KMS key:
those are monthly and expected to remain.

## Known debt (ADR-0006)

- The cluster API endpoint is **public**, with IAM authentication. GitHub-hosted
  runners have no fixed addresses. Production Readiness makes it private and
  moves to pull-based GitOps.
- The CI apply role gets **cluster-admin** through an access entry. It needs far
  less than that.

## Prerequisites

The bootstrap must be applied: this root reads its VPC, private subnets and CI
role ARN. The Makefile reads them from the bootstrap's outputs, so no account
details are written down here.
