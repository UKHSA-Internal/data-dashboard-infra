locals {
  region  = "eu-west-2"
  project = "uhd"
  account = terraform.workspace

  is_dev = contains(["dev", "auth-dev"], local.account)

  observability_platform_account_ids = {
    dev        = "943339978990"
    "auth-dev" = "943339978990"
    uat        = "825834484886"
  }
  observability_platform_account_id = try(
    local.observability_platform_account_ids[local.account],
    null
  )
  create_observability_role = local.observability_platform_account_id != null

  wke_dns_names = {
    dev       = "dev.ukhsa-dashboard.data.gov.uk"
    auth-dev  = "non-public-dev.ukhsa-dashboard.data.gov.uk"
    test      = "test.ukhsa-dashboard.data.gov.uk"
    auth-test = "non-public-test.ukhsa-dashboard.data.gov.uk"
    pen       = "pen.ukhsa-dashboard.data.gov.uk"
    perf      = "perf.ukhsa-dashboard.data.gov.uk"
    auth-perf = "non-public-perf.ukhsa-dashboard.data.gov.uk"
    uat       = "uat.ukhsa-dashboard.data.gov.uk"
    train     = "train.ukhsa-dashboard.data.gov.uk"
    auth-uat  = "non-public-uat.ukhsa-dashboard.data.gov.uk"
    auth-prod = "non-public.ukhsa-dashboard.data.gov.uk"
    prod      = "ukhsa-dashboard.data.gov.uk"
  }
}

locals {
  ship_cur_to_green_ops_dashboard = true
}
