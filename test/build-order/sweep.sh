#!/usr/bin/env bash
# Every engine module as the first one a program names: does it type-check?
#
# Haxe can infer a type differently by the order it types modules in. `final x = a ?? b`, with
# `b` nullable, came out `T` and not `Null<T>` in a game whose first engine module was AnimParser
# and which had a res folder, and @:nullSafety refused it there, while every build of this repo
# passed (f5ada56). For each module under src/ this compiles a program that imports that module
# alone, beside a res folder (res/README.txt), so each module is once the first to be typed.
#
# From the repo root (Git Bash on Windows too):  test/build-order/sweep.sh [haxe args]
#   test/build-order/sweep.sh -D MULTIANIM_DEV
# Compile only, nothing runs. One compile per CPU at a time; BUILD_ORDER_JOBS sets how many.
set -u
cd "$(dirname "$0")/../.."

# Modules that cannot be first, and why.
skip=(
	bh.base.AtlasMacroInit # a --macro initialiser: hxd.res.Config wants the macro context
	bh.base.FPointAbstract # its abstract's constructor never sets `this`; nothing imports it
)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export work
export extra="$*"

check() {
	local m=$1 dir="$work/$1" out code
	mkdir -p "$dir"
	printf 'import %s;\n\nclass BuildOrder {\n\tstatic function main() {}\n}\n' "$m" > "$dir/BuildOrder.hx"
	for try in 1 2 3; do
		# $extra unquoted: it is several arguments
		out=$(haxe -lib heaps -cp src -cp "$dir" -D resourcesPath=test/build-order/res \
			--macro "bh.base.AtlasMacroInit.init()" -hl "$dir/out.hl" --no-output $extra -main BuildOrder 2>&1)
		code=$?
		# 0 and 1 are the compiler's answers; anything else is the compiler crashing, so again
		[ $code -le 1 ] && break
	done
	if [ $code -eq 0 ]; then
		echo ok > "$dir/result"
	else
		{ echo "FAIL $m (exit $code)"; echo "$out" | grep -v '^$' | head -5; } > "$dir/result"
	fi
}
export -f check

modules=$(find src -name '*.hx' | sed 's|^src/||; s|\.hx$||; s|/|.|g' | sort)
for s in "${skip[@]}"; do modules=$(echo "$modules" | grep -vx "$s"); done
count=$(echo "$modules" | wc -l | tr -d ' ')
jobs=${BUILD_ORDER_JOBS:-$(nproc 2>/dev/null || echo 2)}
echo "build order: $count modules, $jobs at a time${extra:+, $extra}"

echo "$modules" | xargs -P "$jobs" -I{} bash -c 'check "$1"' _ {}

failed=0
for m in $modules; do
	r=$(cat "$work/$m/result" 2>/dev/null || echo "FAIL $m (no result)")
	if [ "$r" != ok ]; then
		echo "$r"
		failed=$((failed + 1))
	fi
done
if [ $failed -gt 0 ]; then
	echo "build order: $failed of $count modules do not compile when typed first"
	exit 1
fi
echo "build order: OK ($count modules)"
