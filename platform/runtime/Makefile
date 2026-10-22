# Bring the path 02 session cluster up and down.
#
# Everything here costs money by the hour, so the only two commands that
# matter are session-up and session-down. ADR-0006: a human runs these
# locally; CI never creates or destroys the cluster.

SHELL := /usr/bin/env bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

AWS_PROFILE ?= meridian-sandbox
REGION      ?= eu-west-1
BOOTSTRAP   := ../bootstrap
TF          := mise exec -- terraform
export AWS_PROFILE

# Read the bootstrap's outputs rather than writing account details down.
bootstrap_out = $(shell $(TF) -chdir=$(BOOTSTRAP) output -raw $(1) 2>/dev/null)

.PHONY: help init plan session-up session-down check kubeconfig cost

help:
	@echo "make session-up     bring the cluster up (about 15 minutes)"
	@echo "make session-down   destroy it, then check nothing is left billing"
	@echo "make plan           show what session-up would create"
	@echo "make check          check for hourly-billed resources, without destroying"
	@echo "make kubeconfig     point kubectl at the session cluster"
	@echo "make cost           what a session costs per hour"

init:
	@bucket="$(call bootstrap_out,state_bucket_name)"
	if [ -z "$$bucket" ]; then
	  echo "Could not read the state bucket from $(BOOTSTRAP)." >&2
	  echo "Run: terraform -chdir=$(BOOTSTRAP) init -backend-config=\"bucket=<name>\"" >&2
	  exit 1
	fi
	$(TF) init -backend-config="bucket=$$bucket" -upgrade

TF_VARS = \
  -var="vpc_id=$(call bootstrap_out,vpc_id)" \
  -var="ci_apply_role_arn=$(call bootstrap_out,ci_apply_role_arn)" \
  -var="datastore_clients_security_group_id=$(call bootstrap_out,datastore_clients_security_group_id)" \
  -var='private_subnet_ids=$(shell $(TF) -chdir=$(BOOTSTRAP) output -json private_subnet_ids 2>/dev/null)'

plan: init
	$(TF) plan $(TF_VARS)

session-up: init
	@echo "Bringing the session up. This costs about USD 0.17 an hour."
	$(TF) apply -auto-approve $(TF_VARS)
	@echo
	@$(TF) output -raw kubeconfig_command
	@echo
	@echo "Remember: make session-down when you are finished."

# The check runs whether or not destroy succeeded, which is the case that
# matters: a half-failed destroy is exactly when something is left running.
session-down: init
	@set +e
	$(TF) destroy -auto-approve $(TF_VARS)
	status=$$?
	set -e
	if [ $$status -ne 0 ]; then
	  echo
	  echo "terraform destroy failed. Checking what is left anyway." >&2
	fi
	echo
	./scripts/check_no_hourly_resources.sh $(REGION)

check:
	@./scripts/check_no_hourly_resources.sh $(REGION)

kubeconfig:
	@aws eks update-kubeconfig --name meridian-session --region $(REGION)

cost:
	@echo "Per hour, eu-west-1 list prices:"
	@echo "  EKS control plane          0.100"
	@echo "  NAT gateway                0.048   (plus data processed)"
	@echo "  Elastic IP (in use)        0.005"
	@echo "  2 nodes, spot        0.017-0.059   (t4g.small to m7g.medium)"
	@echo "  ----------------------------------"
	@echo "  about               0.170-0.212   ~USD 1.36-1.70 for an 8-hour day"
	@echo ""
	@echo "The range is which spot pool EKS can get. Cheapest is two"
	@echo "t4g.small; worst case two m7g.medium, about 4 cents an hour more."
