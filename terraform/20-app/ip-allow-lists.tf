locals {
  ip_allow_list = {
    engineers = [
      "90.250.132.232/32",  # Afaan
      "154.51.68.102/32",   # Burendo Leeds
      "167.98.124.170/32",  # Burendo London
      "90.219.251.228/32",  # Phil
      "90.241.8.192/32",    # Rhys Inlaws
      "82.132.245.244/32",  # Rhys hotspot
      "86.2.63.107/32",     # Rhys Home
      "86.173.151.83/32",   # Luke
      "86.9.184.205/32",    # Manu
    ],
    project_team = [
      "77.100.107.252/32",  # Laura
      "5.81.132.150/32",    # Khawar
      "86.19.165.183/32",   # Ehsan
    ],
    other_stakeholders = [
      "62.253.228.56/32",   # UKHSA gateway
      "86.159.135.80/32",   # Asad
      "62.253.228.2/32",    # 10SC
      "109.153.151.195/32", # Ciara
      "66.249.74.35/32",    # Ciara 2
      "136.226.191.116/32", # Charlotte Brace
      "90.213.214.30/32",   # Ruth Baxter
      "86.11.171.6/32",     # Jason Deakin
      "147.161.236.110/32", # Jason Deakin 2
      "194.9.109.118/32",   # Georgina Milne
      "172.28.215.10/32",   # Alana Firth
      "165.225.17.43/32",   # Maria Tsiko
      "136.226.167.91/32",  # Emmanuel Ughoo
      "147.161.224.180/32"  # Osazee Ogunje
      "147.161.236.80/32",  # Jayne Gilbert
    ]
    pen_testers = [
      "82.68.136.38/32",    # Steve Ryan
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
        local.ip_allow_list.other_stakeholders,
        # Add pen testers IP addresses only for the `pen` test environment
        local.environment == "pen" ? local.ip_allow_list.pen_testers : []
      )
    )
  )
}
