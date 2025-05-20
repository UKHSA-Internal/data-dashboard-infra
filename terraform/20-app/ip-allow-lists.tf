locals {
  ip_allow_list = {
    engineers = [
      "81.79.20.84/32",     # Afaan
      "154.51.68.102/32",   # Burendo Leeds
      "167.98.124.170/32",  # Burendo London
      "90.219.251.228/32",  # Phil
      "81.78.9.5/32",       # Rhys Inlaws
      "82.132.245.244/32",  # Rhys hotspot
      "86.3.218.23/32",     # Rhys Home
      "35.176.13.254/32",   # UKHSA test EC2
      "35.176.178.91/32",   # UKHSA test EC2
      "35.179.30.107/32",   # UKHSA test EC2
      "18.133.111.70/32",   # UKHSA test gateway
      "147.161.143.117/32", # Kiran Golla
      "92.234.44.48/32",    # Zesh
      "86.130.56.139/32",   # Luke
      "147.161.236.91/32",  # Jeff Thomas - Windows
      "81.106.144.243/32",  # Jeff Thomas - Macbook
      "146.198.70.45/32",   # Mike Elshaw
      "136.226.191.85/32",  # Manu
    ],
    project_team = [
      "90.196.180.145/32", # Debbie
    ],
    other_stakeholders = [
      "62.253.228.56/32",   # UKHSA gateway
      "109.147.97.65/32",   # Khawar
      "86.19.165.183/32",   # Ehsan
      "90.196.35.64/32",    # Kelly
      "86.159.135.80/32",   # Asad
      "18.135.62.168/32",   # Load test rig
      "62.253.228.2/32",    # Office ? / UKHSA ? / Asad
      "82.68.136.38/32",    # Steve Ryan
      "109.153.151.195/32", # Ciara
      "66.249.74.35/32",    # Ciara 2
      "2.25.205.147/32",    # Prince
      "86.128.102.66/32",   # Ester
      "147.161.237.1/32",   # Tom Hebbert Home
      "81.105.235.133/32",  # Tom Hebbert 2
      "51.149.2.8/32",      # Agostinho Sousa
      "136.226.191.116/32", # Charlotte Brace
      "2.221.74.175/32",    # Gareth
      "81.108.143.100/32",  # Ruairidh Villar
      "90.218.199.1/32",    # Ruth Baxter
      "86.11.171.6/32",     # Jason Deakin
      "194.9.109.92/32",    # Jason Deakin 2
      "194.9.109.118/32",   # Georgina Milne
    ]
    pen_testers = []
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
