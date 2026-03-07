#!/bin/bash

TARGET="${1:-}"

case "$TARGET" in
  sdwc-api)
    kubectl logs -l app=sdwc-api -n sdwc -f ;;
  sdwc-web)
    kubectl logs -l app=sdwc-web -n sdwc -f ;;
  intake-api)
    kubectl logs -l app=intake-assistant-api -n intake -f ;;
  intake-web)
    kubectl logs -l app=intake-assistant-web -n intake -f ;;
  sdwc)
    kubectl logs -l app=sdwc-api -n sdwc --prefix -f &
    kubectl logs -l app=sdwc-web -n sdwc --prefix -f &
    wait ;;
  intake)
    kubectl logs -l app=intake-assistant-api -n intake --prefix -f &
    kubectl logs -l app=intake-assistant-web -n intake --prefix -f &
    wait ;;
  all|"")
    kubectl logs -l app=sdwc-api -n sdwc --prefix -f &
    kubectl logs -l app=sdwc-web -n sdwc --prefix -f &
    kubectl logs -l app=intake-assistant-api -n intake --prefix -f &
    kubectl logs -l app=intake-assistant-web -n intake --prefix -f &
    wait ;;
  *)
    echo "Usage: $0 [sdwc-api|sdwc-web|intake-api|intake-web|sdwc|intake|all]"
    exit 1 ;;
esac
