# Handover Documentation

## Weather health alerts ETL

Weather health alerts are provided to the product in a slightly different way to the rest of the data ingested by 
the UKHSA data dashboard.

The ETL itself lives in the `data-dashboard-etl-infra` repo.

To allow that ETL pipeline to publish data files to the ingest bucket of this environment, 
edit the `is_ready_for_etl` local variable and add the name of the environment which you want to open permissions for
so that it can receive those weather heath alerts.
