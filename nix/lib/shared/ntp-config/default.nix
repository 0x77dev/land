_: {
  # NTP servers with standard leap second handling (no smearing).
  # Excludes: time.google.com, time.aws.com, time.facebook.com (all smear)
  defaultServers = [
    "time.cloudflare.com" # Global anycast, documented non-smearing
    "time.nist.gov" # US government stratum 1
    "ntp.se" # Netnod Sweden, stratum 1 anycast
    "pool.ntp.org" # Distributed fallback
  ];
}
