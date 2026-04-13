locals {
  ip_allow_list = {
    engineers = [
      "154.51.68.102/32",   # Burendo Leeds
      "167.98.124.170/32",  # Burendo London
      "90.219.251.228/32",  # Phil
      "82.28.94.171/32",    # Phil 2
      "86.2.63.107/32",     # Rhys
      "95.144.23.208/32",   # Luke
      "81.98.116.189/32",   # Manu
      "140.228.53.64/32",   # Josh
      "2.98.245.215/32",    # Matt R
      "82.42.127.246/32",   # Taiwo
      "191.101.81.106/32",  # Shahrukh
      "176.35.199.118/32",  # Aidan
      "82.68.5.88/32",      # Kathryn
      "92.234.124.180/32",  # Kathryn 2
      "86.164.67.191/32",   # Yomi
      "92.21.57.49/32",     # Pete
      "102.129.155.34/32",  # Dan
      "82.33.136.192/32",   # marco
      "149.107.78.78/32",   # scott
    ],
    project_team = [
      "77.100.107.252/32",  # Laura
      "109.156.183.33/32",  # Khawar
      "80.1.86.138/32",     # Ehsan
      "92.234.44.48/31",    # Zesh
      "86.24.105.111/32",   # Subhana
      "86.0.177.34/32",     # Chadrak
    ],
    other_stakeholders = [
      "62.253.228.56/32",   # UKHSA gateway
      "86.159.135.80/32",   # Asad
      "62.253.228.2/32",    # 10SC
      "109.153.151.195/32", # Ciara
      "66.249.74.35/32",    # Ciara 2
      "136.226.191.116/32", # Charlotte Brace
      "194.9.112.198/32",   # Ruth Baxter
      "86.11.171.6/32",     # Jason Deakin
      "147.161.236.110/32", # Jason Deakin 2
      "194.9.109.118/32",   # Georgina Milne
      "172.28.215.10/32",   # Alana Firth
      "165.225.17.43/32",   # Maria Tsiko
      "136.226.167.91/32",  # Emmanuel Ughoo
      "147.161.224.180/32", # Osazee Ogunje
      "165.225.199.111/32", # Jayne Gilbert
      "90.252.15.44/32",    # Andrew Williams
      "172.27.130.67/32",   # Dan Jendrissek
      "194.9.111.78/32",    # Alexandra Yearbridge
      "86.177.109.255/32",  # Jean-Pierre Fouche
      "147.161.237.115/32", # Hashim Malik
      "86.134.220.148/32",  # Hassan Hashmi
      "165.225.197.15/32",  # Mike Elshaw
      "165.225.197.22/32",  # Mike Elshaw
      "35.176.13.254/32",   # Mike Elshaw
    ]
    pen_testers = [
      "82.68.136.38/32",    # Steve Ryan
    ],
    perf_testers = [
      "172.25.173.128/26",   # Mike Elshaw's perf runners
      "18.133.90.54/32",     # Mike Elshaw's perf runner
    ],
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
        local.environment == "pen" ? local.ip_allow_list.pen_testers : [],
        # add perf testers IP addresses only for the `perf` test environment
        local.environment == "perf" ? local.ip_allow_list.perf_testers: [],
      )
    )
  )
}
