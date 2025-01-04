# OCI Kubernetes Cluster

This repository provides configuration for Oracle Cloud Infrastructure that uzilizes free tier to deploy (almost) free Kubernetes cluster.

## Requirements

- OCI Account with free tier
- Cloudflare Account
- Domain for ingress

## Why almost?

There are charges for volumes related to clickhouse. But if you do not need clickhouse in your deployment. Your cluster should run completely for free.
