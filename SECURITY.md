# Security Policy

## Supported scope

This repository is Mykhailo's Nix-managed infrastructure. Security-sensitive
changes are reviewed and landed through pull requests; generated secrets and live
machine credentials are intentionally kept out of git.

## Reporting a vulnerability

Please report vulnerabilities privately to the repository owner instead of filing
a public issue with exploit details. If you do not already have a private contact
path, open a minimal GitHub issue that says a private security report is needed
and omit payloads, credentials, hostnames, or reproduction details until a private
channel is established.

## Automation

GitHub secret scanning, Dependabot security updates, and GitHub-managed CodeQL
run alongside the flake CI.
