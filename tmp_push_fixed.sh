#!/bin/bash
# Fixed asset pusher: drains accumulated commits one by one, then commits and
# pushes each remaining rite_bg file individually. Success = git push exit 0.
cd "$(dirname "$0")" || exit 1

git restore --staged . 2>/dev/null

push_one() { # $1 = refspec target (sha or 'main'); returns 0 on verified success
  local target="$1" attempt
  for attempt in 1 2 3 4 5; do
    if out=$(git push origin "$target:main" 2>&1); then
      return 0
    fi
    # Ambiguous case: push landed but response was lost -> retry reports
    # up-to-date with exit 0. Real failures fall through and retry.
    echo "  fail #$attempt: $(echo "$out" | tail -1); retry in 15s"
    sleep 15
  done
  return 1
}

# Phase 1: drain commits already made but not pushed.
while :; do
  pending=$(git rev-list --reverse origin/main..main | head -1)
  [ -z "$pending" ] && break
  short=$(git log -1 --format='%h %s' "$pending")
  if push_one "$pending"; then
    echo "drained: $short"
  else
    echo "STOP: cannot drain $short"; exit 1
  fi
done
echo "phase 1 done, local == remote at $(git rev-parse --short origin/main)"

# Phase 2: commit remaining untracked rite_bg pngs one at a time, push each.
mapfile -t files < <(git status --porcelain | awk '$1=="??" {print $2}' | grep 'rite_bg/.*\.png$' | sort)
echo "remaining pngs: ${#files[@]}"
for f in "${files[@]}"; do
  imp="$f.import"
  if [ -f "$imp" ]; then git add "$f" "$imp"; else git add "$f"; fi
  git commit -q -m "assets: rite bg $(basename "$f")"
  if push_one main; then
    echo "pushed: $(basename "$f") ($(git rev-parse --short HEAD))"
  else
    echo "STOP: committed $(basename "$f") but cannot push; inspect network"
    exit 1
  fi
done

echo "all done. remaining untracked:"
git status --porcelain | head -10
