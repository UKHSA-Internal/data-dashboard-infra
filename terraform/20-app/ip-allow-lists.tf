locals {
  ip_allow_list = {
    engineers = [
      "89.36.121.186/32",   # Afaan
      "154.51.68.102/32",   # Burendo Leeds
      "167.98.124.170/32",  # Burendo London
      "94.2.218.102/32",    # Phil
      "93.96.77.57/32",     # Rhys
      "86.6.247.91/32",     # Tom
      "35.176.13.254/32",   # UKHSA test EC2
      "35.176.178.91/32",   # UKHSA test EC2
      "35.179.30.107/32",   # UKHSA test EC2
      "18.133.111.70/32",   # UKHSA test gateway
      "147.161.143.82/32",  # Krishna
      "80.7.227.61/32",     # Kiran
      "92.234.44.48/32",    # Zesh
    ],
    project_team = [
      "90.221.143.3/32",    # Debbie
    ],
    other_stakeholders = [
      "62.253.228.56/32",   # UKHSA gateway 
      "80.5.156.26/32",     # Khawar
      "86.19.165.183/32",   # Ehsan
      "90.196.35.64/32",    # Kelly
      "86.159.135.80/32",   # Asad
      "217.155.89.135/32",  # Zoe Brass
      "18.135.62.168/32",   # Load test rig
      "62.253.228.2/32",    # Office ? / UKHSA ? / Asad
      "82.68.136.38/32",    # Steve Ryan
      "90.208.183.134/32",  # Christie
      "109.153.151.195/32", # Ciara
      "86.151.190.40/32",   # Ciara 2
      "2.25.205.147/32",    # Prince
      "86.128.102.66/32",   # Ester
      "172.29.176.6/32",    # Splunk synthetic monitioring - Azure UK South
      "167.98.243.140/32",  # Tom H
      "81.105.235.133/32",  # Tom H 2
      "51.149.2.8/32",      # Agostinho Sousa
      "86.29.186.201/32",   # Charlotte Brace
      "2.221.74.175/32",    # Gareth
      "81.108.143.100/32",  # Ruairidh Villar
    ]
  }
  complete_ip_allow_list = tolist(
    # Cast back to a list for portability
    toset(
      # Cast the whole list to a set
      # to deduplicate any IP addresses
      # This should prevent duplicated IP addresses
      # from being included.
      # Which breaks the load balancers on deployments
      concat(
        # Combine all the sublists since the whole
        # list is used for access to the WAFs
        local.ip_allow_list.engineers,
        local.ip_allow_list.project_team,
        local.ip_allow_list.other_stakeholders
      )
    )
  )
}
