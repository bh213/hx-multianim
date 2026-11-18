#!/usr/bin/env bash
# Every engine module compiled on one compilation server, more than once: does a later compile
# give what the first gave?
#
# A game built on a compilation server (`haxe --wait`) passed its first compile and failed every
# later one with "Null safety: Cannot use nullable value of … as an item in Array<…>", where a
# cold compile passed. The server keeps a module's typed code from one compile to the next, and
# @:nullSafety read again what it had passed: a local function that calls itself, in a
# @:nullSafety class, on HashLink (a JavaScript build did not show it). No build of this repo
# compiles twice on one server, so none saw it.
#
# This compiles one program that imports every module under src/, three times on one server.
#
# From the repo root (Git Bash on Windows too):  test/compile-server/twice.sh [haxe args]
#   test/compile-server/twice.sh -D MULTIANIM_DEV
# Compile only, nothing runs. COMPILE_SERVER_PORT sets the port (6719).
set -u
cd "$(dirname "$0")/../.."

# Modules that cannot be imported, and why (test/build-order/sweep.sh has the same two).
skip=(
	bh.base.AtlasMacroInit # a --macro initialiser: hxd.res.Config wants the macro context
	bh.base.FPointAbstract # its abstract's constructor never sets `this`; nothing imports it
)

port=${COMPILE_SERVER_PORT:-6719}
compiles=3
work=$(mktemp -d)
server=
trap '[ -n "$server" ] && kill "$server" 2>/dev/null; rm -rf "$work"' EXIT

modules=$(find src -name '*.hx' | sed 's|^src/||; s|\.hx$||; s|/|.|g' | sort)
for s in "${skip[@]}"; do modules=$(echo "$modules" | grep -vx "$s"); done
count=$(echo "$modules" | wc -l | tr -d ' ')
{
	for m in $modules; do echo "import $m;"; done
	printf '\nclass CompileTwice {\n\tstatic function main() {}\n}\n'
} > "$work/CompileTwice.hx"

# The compiler itself, not lix's `haxe`: lix's own server listens on every network interface and
# its client speaks only to that server. lix gives a program it runs the compiler's std folder,
# and the compiler is beside it.
printf 'class Where {\n\tstatic function main() Sys.println(Sys.getEnv("HAXE_STD_PATH"));\n}\n' > "$work/Where.hx"
std=$(haxe -cp "$work" --run Where 2>/dev/null | tr -d '\r' | tr '\\' '/')
compiler="$(dirname "$std")/haxe"
[ -x "$compiler.exe" ] && compiler="$compiler.exe"
if [ -z "$std" ] || [ ! -x "$compiler" ]; then
	echo "compile server: no compiler beside the std folder lix names ($std)"
	exit 1
fi

# The arguments with lix's libraries as class paths, one a line. $* unquoted: several arguments.
args=()
while IFS= read -r line; do
	[ -n "$line" ] && args+=("$line")
done < <(haxe --run resolve-args -lib heaps -cp src -cp "$work" -D resourcesPath=test/build-order/res \
	--macro "bh.base.AtlasMacroInit.init()" -hl "$work/out.hl" --no-output $* -main CompileTwice | tr -d '\r')

HAXE_STD_PATH="$std" "$compiler" --wait "127.0.0.1:$port" > "$work/server.log" 2>&1 &
server=$!
for try in $(seq 1 50); do
	"$compiler" --connect "127.0.0.1:$port" --version > /dev/null 2>&1 && break
	if ! kill -0 "$server" 2>/dev/null || [ "$try" -eq 50 ]; then
		echo "compile server: no server on 127.0.0.1:$port"
		cat "$work/server.log"
		exit 1
	fi
	sleep 0.2
done

echo "compile server: $count modules, $compiles compiles on one server${*:+, $*}"
failed=0
for n in $(seq 1 "$compiles"); do
	out=$("$compiler" --connect "127.0.0.1:$port" "${args[@]}" 2>&1)
	code=$?
	if [ $code -ne 0 ]; then
		echo "FAIL compile $n (exit $code)"
		echo "$out" | grep -v '^$' | cut -c1-240 | head -40
		failed=$((failed + 1))
	fi
done
if [ $failed -gt 0 ]; then
	echo "compile server: $failed of $compiles compiles failed"
	exit 1
fi
echo "compile server: OK ($compiles compiles)"
