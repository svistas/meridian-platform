# The platform's customer-managed key. Every datastore this path creates is
# encrypted with this key, whatever its classification (ADR-0002).

resource "aws_kms_key" "datastores" {
  description             = "Meridian platform: encryption for datastores created by path 01"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "datastores" {
  name          = "alias/meridian-datastores"
  target_key_id = aws_kms_key.datastores.key_id
}
