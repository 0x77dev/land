_: {
  # Default NTP servers with standard leap second handling (no smearing).
  # Safe to use together and with GPS/PPS time sources.
  #
  # EXCLUDED servers (leap smearing incompatible with standard NTP/GPS):
  # - time.google.com - smears since 2008
  # - time.aws.com - smears
  # - time.facebook.com - smears
  # - amazon.pool.ntp.org - NOT run by Amazon, just a pool.ntp.org vendor zone
  defaultServers = [
    # Cloudflare - explicitly documented as non-smearing
    # https://developers.cloudflare.com/time-services/ntp/
    "time.cloudflare.com"

    # NIST - US government time standard (stratum 1)
    "time.nist.gov"
    "time-a-g.nist.gov"
    "time-b-g.nist.gov"

    # Internet Systems Consortium
    "clock.isc.org"

    # Netnod Sweden - stratum 1, anycast
    "ntp.se"

    # TimeNL/SIDN Labs - Dutch stratum 1, NTS support
    "ntp.time.nl"

    # RIPE NCC
    "ntp.ripe.net"

    # Hurricane Electric - stratum 1
    "clock.sjc.he.net"
    "clock.nyc.he.net"

    # NICT Japan - National Institute of Information and Communications Technology
    "ntp.nict.jp"

    # Austrian Academic Computer Network
    "ts1.aco.net"
    "ts2.aco.net"

    # Hetzner - European hosting provider
    "ntp1.hetzner.de"
    "ntp2.hetzner.de"

    # NTP Pool - distributed, standard behavior (no smearing allowed)
    "pool.ntp.org"
  ];
}
