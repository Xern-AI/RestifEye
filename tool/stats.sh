#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-Xern-AI/RestifEye}"

printf '\n== Release downloads (all time, %s) ==\n\n' "$REPO"
gh api "repos/$REPO/releases" --paginate --jq \
  '.[] | "\(.tag_name)\t\(.assets[] | "\(.name) \(.download_count)")"' |
  awk -F'\t' '{split($2,a," "); printf "  %-12s %-42s %6d\n", $1, a[1], a[2]; total+=a[2];
              if (a[1] ~ /\.AppImage$/) app+=a[2];
              else if (a[1] ~ /\.rpm$/)  rpm+=a[2];
              else if (a[1] ~ /\.deb$/)  deb+=a[2] }
       END { printf "\n  AppImage %d   RPM %d   DEB %d\n  TOTAL    %d\n", app, rpm, deb, total }'

printf '\n== Repo traffic (github.com pages, rolling 14 days) ==\n\n'
gh api "repos/$REPO/traffic/views" --jq \
  '"  views   \(.count) total, \(.uniques) unique visitors"'
gh api "repos/$REPO/traffic/clones" --jq \
  '"  clones  \(.count) total, \(.uniques) unique cloners"'

printf '\n  top referrers:\n'
gh api "repos/$REPO/traffic/popular/referrers" --jq \
  '.[] | "    \(.referrer)\t\(.count) views, \(.uniques) unique"' | expand -t 28

printf '\n  top paths:\n'
gh api "repos/$REPO/traffic/popular/paths" --jq \
  '.[] | "    \(.path)\t\(.count) views, \(.uniques) unique"' | expand -t 60

printf '\n== Repo ==\n\n'
gh api "repos/$REPO" --jq '"  \(.stargazers_count) stars   \(.forks_count) forks   \(.subscribers_count) watchers"'
printf '\n'
