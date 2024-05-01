locals {
  ip_allow_list = {
    engineers = [
      "185.241.164.214/32", # Afaan
      "82.132.235.146/32",  # Afaan's phone
      "154.51.68.102/32",   # Burendo
      "82.2.4.244/32",      # Kev
      "78.147.110.81/32",   # Kev 2
      "31.94.59.185/32",    # Kev's phone
      "188.220.4.44/32",    # Phil
      "94.0.1.168/32",   # Rhys
      "82.23.201.161/32",   # Tom
      "35.176.13.254/32",   # UKHSA test EC2
      "35.176.178.91/32",   # UKHSA test EC2
      "35.179.30.107/32",   # UKHSA test EC2
      "18.133.111.70/32",   # UKHSA test gateway
      "81.108.89.51/32",    # Krishna
      "80.7.227.61/32",     # Kiran
    ],
    project_team = [
      "78.105.5.74/32", # Debbie
    ],
    other_stakeholders = [
      "62.253.228.56/32",   # Georgina
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
      "81.105.235.133/32"   # Tom H
    ]
  }
}
