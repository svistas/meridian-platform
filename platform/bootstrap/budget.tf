# Account budget (ADR-0003: "the budget alert exists before the first database
# is created"). Two notifications: one when real spend passes 80% of the limit,
# one when the forecast for the month passes the limit.

resource "aws_budgets_budget" "sandbox" {
  name         = "meridian-sandbox-monthly"
  budget_type  = "COST"
  limit_amount = var.budget_limit_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}

# Daily budget, for the failure mode a monthly budget cannot catch in time.
#
# Path 02 runs ephemeral EKS sessions. A session left running overnight costs
# far more per hour than anything path 01 creates, and a monthly budget only
# notices once the damage is weeks old. A daily budget raises its hand the
# morning after.
#
# ACTUAL only, not FORECASTED: a forecast over a single day is noise, and a
# daily forecast alert would fire often enough to be ignored.

resource "aws_budgets_budget" "sandbox_daily" {
  name         = "meridian-sandbox-daily"
  budget_type  = "COST"
  limit_amount = var.budget_daily_limit_usd
  limit_unit   = "USD"
  time_unit    = "DAILY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}
