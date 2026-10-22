# The root module is the whole interface between a request file and AWS.
#
# It reads every request in ../requests, and creates exactly one datastore per
# request. Adding a file creates a database; removing a file destroys it. The
# request cannot influence anything in the guarantee table -- those properties
# live in the module, not here.

locals {
  request_files = fileset("${path.module}/../requests", "*.yaml")

  requests = {
    for file in local.request_files :
    trimsuffix(file, ".yaml") => yamldecode(file("${path.module}/../requests/${file}"))
  }

  # YAML turns an unquoted `no` into the boolean false, so the same answer can
  # arrive as "no", "No" or false. Normalise it the way validate_requests.py
  # does, or the tag would read "false" for half the requests.
  data_leaves_meridian = {
    for name, request in local.requests :
    name => contains(["no", "false"], lower(tostring(request.data_leaves_meridian))) ? "no" : lower(tostring(request.data_leaves_meridian))
  }
}

module "postgres" {
  source   = "./modules/postgres"
  for_each = local.requests

  # From the request.
  service              = each.value.service
  team                 = each.value.team
  cost_center          = each.value.cost_center
  classification       = each.value.classification
  size                 = each.value.size
  data_leaves_meridian = local.data_leaves_meridian[each.key]

  # From the bootstrap.
  kms_key_arn          = var.kms_key_arn
  db_subnet_group_name = var.db_subnet_group_name
  vpc_id               = var.vpc_id
  engine_version       = var.engine_version

  datastore_clients_security_group_id = var.datastore_clients_security_group_id
}
