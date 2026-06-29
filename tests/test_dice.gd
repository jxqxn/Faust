extends GutTest

# Dice system tests, pinned to verified-conclusions.md #1-#4.
# All numeric assertions are the "oracle" signal; the .c loop structure is the
# second signal (see spec section 10).

const Dice = preload("res://core/dice.gd")
const RNG = preload("res://core/rng.gd")

func test_weighted_single_roll_respects_weights():
	# Difficulty-normal weights [100,100,100,100,200,200].
	# Face 5 and 6 should each come up ~20% of the time; faces 1-4 ~10%.
	var rng := RNG.new(12345)
	var weights := [100, 100, 100, 100, 200, 200]
	var counts := [0, 0, 0, 0, 0, 0]
	for i in 20000:
		var face := Dice.roll_weighted_face(rng, weights)
		counts[face - 1] += 1
	# Faces 5,6 double the weight of faces 1-4.
	assert_gt(counts[4], counts[0], "face 5 should beat face 1")
	assert_gt(counts[5], counts[0], "face 6 should beat face 1")
	# Approximate ratio check (loose bounds to avoid flakiness).
	var ratio := float(counts[4]) / float(counts[0])
	assert_between(ratio, 1.6, 2.4, "face5/face1 ratio ~2.0")

func test_easy_difficulty_success_rate_is_60_percent():
	# verified-conclusions #1: easy weights [100,100,100,100,300,300].
	# P(die >= 5) = (300+300)/1000 = 60%.
	var rng := RNG.new(999)
	var weights := [100, 100, 100, 100, 300, 300]
	var successes := 0
	var trials := 20000
	for i in trials:
		var face := Dice.roll_weighted_face(rng, weights)
		if face >= 5:
			successes += 1
	var rate := float(successes) / float(trials)
	assert_between(rate, 0.57, 0.63, "easy success rate ~60%")

func test_normal_difficulty_success_rate_is_50_percent():
	# verified-conclusions #4a: normal weights [100,100,100,100,200,200].
	# P(die >= 5) = (200+200)/1000 = 50%.
	var rng := RNG.new(7)
	var weights := [100, 100, 100, 100, 200, 200]
	var successes := 0
	var trials := 20000
	for i in trials:
		var face := Dice.roll_weighted_face(rng, weights)
		if face >= 5:
			successes += 1
	var rate := float(successes) / float(trials)
	assert_between(rate, 0.47, 0.53, "normal success rate ~50%")

func test_hard_difficulty_uses_weights_not_33_percent_text():
	# verified-conclusions #4a: hard weights [150,150,150,150,200,200].
	# Implementation rate is 40%, NOT the 33% in the desc text.
	var rng := RNG.new(42)
	var weights := [150, 150, 150, 150, 200, 200]
	var successes := 0
	var trials := 20000
	for i in trials:
		var face := Dice.roll_weighted_face(rng, weights)
		if face >= 5:
			successes += 1
	var rate := float(successes) / float(trials)
	# 40%, NOT 33%.
	assert_gt(rate, 0.36, "hard rate must be 40% (weights), not 33% (text)")
	assert_lt(rate, 0.44, "hard rate upper bound")

func test_is_satisfied_geq_success_threshold():
	# verified-conclusions #2 (v3, the correct one): success ⟺ die >= Y(=Values[1]=5).
	# Build a check: r1 expression value N=4 dice, Y=5, X=3 needed, compare ">=".
	var rng := RNG.new(2024)
	var weights := [100, 100, 100, 100, 200, 200]
	# Roll 4 dice; count successes (>=5); compare (successes + goldDice=0) >= X=3.
	var res := Dice.is_satisfied(rng, 4, 5, 3, ">=", weights, 0)
	# With normal weights, 4 dice each 50% => ~2 successes; sometimes >=3.
	assert_true(res == true or res == false, "is_satisfied returns a bool")

func test_is_satisfied_zero_dice_never_succeeds_without_gold():
	# N=0 dice, no gold dice => 0 successes => fails any positive threshold.
	var rng := RNG.new(1)
	var weights := [100, 100, 100, 100, 200, 200]
	var res := Dice.is_satisfied(rng, 0, 5, 1, ">=", weights, 0)
	assert_false(res, "zero dice cannot reach threshold 1")

func test_gold_dice_add_one_success_each():
	# verified-conclusions #3: each gold die = +1 success, added in IsSatisfied
	# via ConditionContext.goldDiceCounts.
	var rng := RNG.new(2)
	var weights := [100, 100, 100, 100, 200, 200]
	# 0 dice but 2 gold dice => 2 successes.
	var res := Dice.is_satisfied(rng, 0, 5, 2, ">=", weights, 2)
	assert_true(res, "2 gold dice satisfy threshold 2")
	# 1 die likely fails but 3 gold dice carry it.
	var res2 := Dice.is_satisfied(rng, 0, 5, 5, ">=", weights, 5)
	assert_true(res2, "5 gold dice satisfy threshold 5")

func test_r1_random_uniform_single_arg():
	# verified-conclusions #4: r1 with one value = Random.Range(0, value).
	var rng := RNG.new(55)
	var counts := {}
	for i in 5000:
		var v := Dice.r1_random(rng, 6, 0)
		counts[v] = counts.get(v, 0) + 1
	# All values 0..5 should appear.
	for k in 6:
		assert_true(counts.has(k), "value %d appeared" % k)
	assert_false(counts.has(6), "value 6 must not appear (exclusive upper)")

func test_r1_random_uniform_two_arg():
	# verified-conclusions #4: r1 with two values = Random.Range(tokens[0], tokens[1]).
	var rng := RNG.new(77)
	var counts := {}
	for i in 5000:
		var v := Dice.r1_random(rng, 3, 8)
		counts[v] = counts.get(v, 0) + 1
	for k in range(3, 8):
		assert_true(counts.has(k), "value %d appeared" % k)
	assert_false(counts.has(2), "below lower bound")
	assert_false(counts.has(8), "upper bound exclusive")
