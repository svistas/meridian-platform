#!/usr/bin/env bash
#
# Is anything still costing money by the hour?
#
# `terraform destroy` reports on what Terraform knows about. This asks AWS
# instead, so it also catches what Terraform does not own: a load balancer a
# Kubernetes Service of type LoadBalancer created, an instance someone started
# by hand, an Elastic IP left behind after a failed destroy.
#
# Exits non-zero if anything is found, so `make session-down` fails loudly
# rather than printing a warning nobody reads.
#
# Usage: check_no_hourly_resources.sh [region]

set -uo pipefail

REGION="${1:-${AWS_REGION:-eu-west-1}}"
found=0

say() { printf '%s\n' "$*"; }

report() {
  local label="$1" rate="$2" items="$3"
  if [ -n "$items" ]; then
    found=1
    say ""
    say "  STILL RUNNING  ${label}  (${rate})"
    printf '%s\n' "$items" | tr '\t' '\n' | sed '/^$/d' | sed 's/^/      /'
  else
    say "  clear          ${label}"
  fi
}

say "Checking ${REGION} for hourly-billed resources..."
say ""

report "EKS clusters" "USD 0.10/hr each" \
  "$(aws eks list-clusters --region "$REGION" --query 'clusters' --output text 2>/dev/null)"

report "EC2 instances" "USD 0.0184/hr for a t4g.small on demand" \
  "$(aws ec2 describe-instances --region "$REGION" \
      --filters Name=instance-state-name,Values=pending,running,stopping,shutting-down \
      --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null)"

report "NAT gateways" "USD 0.048/hr each, plus data" \
  "$(aws ec2 describe-nat-gateways --region "$REGION" \
      --filter Name=state,Values=pending,available,deleting \
      --query 'NatGateways[].NatGatewayId' --output text 2>/dev/null)"

report "Load balancers" "from USD 0.027/hr each" \
  "$(aws elbv2 describe-load-balancers --region "$REGION" \
      --query 'LoadBalancers[].LoadBalancerArn' --output text 2>/dev/null)"

report "Classic load balancers" "USD 0.028/hr each" \
  "$(aws elb describe-load-balancers --region "$REGION" \
      --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text 2>/dev/null)"

# Charged whether attached or not, so an orphaned one is pure waste.
report "Elastic IPs" "USD 0.005/hr each" \
  "$(aws ec2 describe-addresses --region "$REGION" \
      --query 'Addresses[].PublicIp' --output text 2>/dev/null)"

say ""
if [ "$found" -ne 0 ]; then
  say "Something is still billing by the hour in ${REGION}."
  say "If it is not yours, check the console before deleting it: this account"
  say "predates the project and has had other things in it (ADR-0003)."
  exit 1
fi

say "Nothing is billing by the hour in ${REGION}."
say "Note: this does not cover storage (EBS, S3, RDS snapshots) or the KMS key,"
say "which are charged by the month and are expected to remain."
exit 0
