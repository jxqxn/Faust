#!/bin/bash
# Push remaining rite_bg PNGs one file per commit.
# Stops after repeated failures so the state can be inspected.
cd "$(dirname "$0")" || exit 1

mapfile -t files < <(git status --short | awk '$1=="??" {print $2}' | grep 'rite_bg/.*\.png$' | sort)
echo "pending pngs: ${#files[@]}"
total_fail=0

for f in "${files[@]}"; do
  imp="$f.import"
  if [ -f "$imp" ]; then git add "$f" "$imp"; else git add "$f"; fi
  base=$(basename "$f")
  if ! git diff --cached --quiet; then
    git commit -q -m "assets: rite bg $base" || { echo "COMMIT FAIL $base"; exit 1; }
  fi
  ok=0
  for attempt in 1 2 3; do
    if git push origin main 2>&1 | grep -v '^Everything up-to-date'; then
      ok=1; break
    fi
    echo "  push fail #$attempt for $base, retry in 20s"
    sleep 20
  done
  if [ $ok -eq 1 ]; then
    echo "pushed: $base ($(git rev-parse --short HEAD))"
  else
    total_fail=$((total_fail+1))
    echo "GAVE UP on $base after 3 attempts"
    if [ $total_fail -ge 2 ]; then echo "two consecutive give-ups, stopping"; exit 1; fi
  fi
done
echo "done. remaining:"
git status --short | head -5
