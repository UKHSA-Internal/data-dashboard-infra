locals {
  region  = "eu-west-2"
  project = "uhd"
  account = terraform.workspace

  wke_dns_names = {
    dev   = "dev.ukhsa-dashboard.data.gov.uk"
    pen   = "pen.ukhsa-dashboard.data.gov.uk"
    perf  = "perf.ukhsa-dashboard.data.gov.uk"
    prod  = "ukhsa-dashboard.data.gov.uk"
    test  = "test.ukhsa-dashboard.data.gov.uk"
    train = "train.ukhsa-dashboard.data.gov.uk"
    uat   = "uat.ukhsa-dashboard.data.gov.uk"
  }
}

locals {
  ship_cloud_watch_metrics_to_splunk = true
}
