#!/bin/bash
# Push remaining assets in ~20MB batches
batch=0
push_dir () {
	local dir="$1"; local label="$2"; local per="$3"
	local files=($(ls "$dir" | grep -v import | grep -E "\.(png|ogg|json)$" | sort))
	local i=0
	while [ $i -lt ${#files[@]} ]; do
		git reset -q 2>/dev/null
		local j=$i local_added=0
		for j in $(seq $i $((i+per-1))); do
			[ $j -lt ${#files[@]} ] || break
			git add "$dir/${files[$j]}" "$dir/${files[$j]}.import" 2>/dev/null
		done
		local n=$(git status --short | grep -c "^A ")
		[ $n -eq 0 ] && { i=$((i+per)); continue; }
		batch=$((batch+1))
		git commit -q -m "assets: $label batch $batch"
		if git push origin main 2>/dev/null; then
			echo "batch $batch ($n files) OK"
		else
			echo "batch $batch FAILED - retrying once"
			sleep 15
			git push origin main 2>/dev/null || { echo "batch $batch FAILED again - stopping"; git reset -q --soft HEAD~1; git reset -q; return 1; }
			echo "batch $batch OK on retry"
		fi
		i=$((i+per))
	done
}
push_dir "assets/original/ui/over_cg" "ending CG" 5
push_dir "assets/original/ui/rite_bg" "rite backgrounds" 4
push_dir "assets/original/ui/rite_slot" "rite slots" 3
echo "=== remaining untracked ==="
git status --short | grep "^??" | grep -v tmp/ | head -5
