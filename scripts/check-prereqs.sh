#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# arch-insights-oss — prerequisite checker
#
# Validates that required and optional tools are installed and
# configured. Missing optional tools print warnings but do not
# cause a non-zero exit.
#
# Usage:  ./scripts/check-prereqs.sh
# ──────────────────────────────────────────────────────────────
set -euo pipefail

PASS="✅"
WARN="⚠️ "
FAIL="❌"
INFO="ℹ️ "

errors=0

header() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  arch-insights-oss — prerequisite check"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# ── Required tools ────────────────────────────────────────────

check_gh() {
  echo "── GitHub CLI ──"
  if ! command -v gh &>/dev/null; then
    echo "  ${FAIL} gh CLI not found — install from https://cli.github.com"
    errors=$((errors + 1))
    return
  fi
  echo "  ${PASS} gh CLI installed ($(gh --version | head -1))"

  if gh auth status --hostname github.com &>/dev/null; then
    echo "  ${PASS} Authenticated to github.com"
  else
    echo "  ${FAIL} Not authenticated — run: gh auth login"
    errors=$((errors + 1))
  fi
}

check_node() {
  echo ""
  echo "── Node.js / npx ──"
  if ! command -v node &>/dev/null; then
    echo "  ${FAIL} Node.js not found — install from https://nodejs.org"
    errors=$((errors + 1))
    return
  fi
  echo "  ${PASS} Node.js installed ($(node --version))"

  if command -v npx &>/dev/null; then
    echo "  ${PASS} npx available"
  else
    echo "  ${FAIL} npx not found (should ship with npm)"
    errors=$((errors + 1))
  fi
}

# ── Optional integrations ────────────────────────────────────

check_prometheus() {
  echo ""
  echo "── Prometheus (optional) ──"
  if [ -z "${PROMETHEUS_URL:-}" ]; then
    echo "  ${INFO} PROMETHEUS_URL not set — Prometheus integration disabled"
    return
  fi
  echo "  ${PASS} PROMETHEUS_URL = ${PROMETHEUS_URL}"

  if curl -sf "${PROMETHEUS_URL}/-/ready" &>/dev/null; then
    echo "  ${PASS} Prometheus is reachable"
  else
    echo "  ${WARN} Prometheus is configured but not reachable at ${PROMETHEUS_URL}"
  fi
}

check_grafana() {
  echo ""
  echo "── Grafana (optional) ──"
  if [ -z "${GRAFANA_URL:-}" ]; then
    echo "  ${INFO} GRAFANA_URL not set — Grafana integration disabled"
    return
  fi
  echo "  ${PASS} GRAFANA_URL = ${GRAFANA_URL}"

  if [ -n "${GRAFANA_API_KEY:-}" ]; then
    echo "  ${PASS} GRAFANA_API_KEY is set"
  else
    echo "  ${WARN} GRAFANA_API_KEY not set — some dashboards may be inaccessible"
  fi
}

check_pagerduty() {
  echo ""
  echo "── PagerDuty (optional) ──"
  if [ -z "${PAGERDUTY_API_KEY:-}" ]; then
    echo "  ${INFO} PAGERDUTY_API_KEY not set — PagerDuty integration disabled"
    return
  fi
  echo "  ${PASS} PAGERDUTY_API_KEY is set"
}

check_slack() {
  echo ""
  echo "── Slack (optional) ──"
  if [ -z "${SLACK_BOT_TOKEN:-}" ]; then
    echo "  ${INFO} SLACK_BOT_TOKEN not set — Slack integration disabled"
    return
  fi
  echo "  ${PASS} SLACK_BOT_TOKEN is set"
}

# ── Summary ───────────────────────────────────────────────────

summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [ "$errors" -gt 0 ]; then
    echo "  ${FAIL} ${errors} required check(s) failed"
    echo "  Fix the issues above and re-run this script."
  else
    echo "  ${PASS} All required prerequisites met!"
    echo "  Optional integrations can be enabled by setting"
    echo "  the corresponding environment variables."
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────

header
check_gh
check_node
check_prometheus
check_grafana
check_pagerduty
check_slack
summary

exit "$errors"
