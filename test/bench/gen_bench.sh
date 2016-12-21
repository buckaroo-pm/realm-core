#!/bin/sh
#
# See ./util/gen_bench.sh --help for documentation.


#The first line of the file "benchmark_version" holds the
#version number, see docs in that file.
BENCH_VERSION=$(head -n 1 benchmark_version)

show_usage () {
  cat <<EOF
Usage: $0 [-h|--help] [<branch>|<commit>|<tag>]
EOF
}

show_help () {
  echo ""
  show_usage
  echo ""
  cat <<EOF
./util/build_core.sh

This script generates the benchmark results for the given version of core
(branch, commit, or tag) and places the results in the directory specified
by REALM_BENCH_DIR (defaults to "~/.realm/core/benchmarks/"). If the results
of the benchmarks on this machine already exist there, the benchmarks are not
run. If no version of core is specified, HEAD is assumed.

Examples:

$ ./util/build_core.sh # HEAD is assumed by default.
$ ./util/build_core.sh tags/v0.97.3 # Tags must be prefixed with "tags/".
$ ./util/build_core.sh ea310804 # Can be a short commit ID.
$ ./util/build_core.sh 32b3b79d2ab90e784ad5f14f201d682be9746781

EOF
}

get_machid () {
    if [ -f "/var/lib/dbus/machine-id" ]; then
        machid=$(cat /var/lib/dbus/machine-id)
    elif [ -f "/etc/machine-id" ]; then
        machid=$(cat /etc/machine-id)
    elif [ -f "/etc/hostname" ]; then
        machid=$(cat /etc/hostname)
    else
        machid=$(ifconfig en0 | awk '/ether/{print $2}')
    fi
    if [ -z "${machid}" ] && [ -f "/proc/self/cgroup" ]; then
        machid=$(cat /proc/self/cgroup | grep docker | grep -o -E '[0-9a-f]{64}' | head -n 1)
    fi
    if [ -z "${machid}" ]; then
        machid="unknown"
    fi
    echo "using machine id: ${machid}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help )
      show_help
      exit 0
      ;;
    * )
      break
      ;;
  esac
done

if [ $# -gt 1 ]; then
    show_usage
    exit 1
elif [ $# -eq 0 ]; then
    ref=$(git rev-parse HEAD)
else
    ref=$1
fi

#get the hash from nice names like tags/v2.0.0
remoteref=$(git rev-list -n 1 "${ref}")
unixtime=$(git show -s --format=%at ${remoteref})


if [ -z "$REALM_BENCH_DIR" ]; then
    REALM_BENCH_DIR=~/.realm/core/benchmarks
fi

get_machid
basedir="${REALM_BENCH_DIR}/${BENCH_VERSION}/${machid}"
mkdir -p "${basedir}"
outputfile="${basedir}/${unixtime}_${remoteref}.csv"

# if the file doesn't exist, create it and write the output dir as the first line
if [ ! -e "recent_results.txt" ] ; then
    echo "${basedir}" > recent_results.txt
fi
echo "${outputfile}" >> recent_results.txt

if [ -f "${outputfile}" ]; then
    echo "found results, skipping ${outputfile}"
else
    headref=$(git rev-parse HEAD)
    if [ "${headref}" = "${remoteref}" ]; then
        echo "building HEAD"
        cd ../..
    else
        sh ./util/build_core.sh "${remoteref}"
        if [ ! -d "core-builds/${remoteref}" ]; then
            echo "fatal error: core checkout failed on ref: ${remoteref}"
            ls -lah
            exit 0
        fi
        cd ../benchmark-common-tasks
        cp main.cpp compatibility.hpp Makefile "../bench/core-builds/${remoteref}/src/test/benchmark-common-tasks"
        echo "unix timestamp of build is ${unixtime}"
        if [ "${unixtime}" -lt "1473070980" ]; then
            echo "Using legacy compatibility of SharedGroup"
            cp compatibility_legacy.cpp "../bench/core-builds/${remoteref}/src/test/benchmark-common-tasks/compatibility.cpp"
        else
            echo "Using normal compatibility of SharedGroup"
            cp compatibility.cpp "../bench/core-builds/${remoteref}/src/test/benchmark-common-tasks/"
        fi
        cd ../benchmark-crud
        cp main.cpp Makefile "../bench/core-builds/${remoteref}/src/test/benchmark-crud/"
        cd ../util
        cp benchmark_results.hpp benchmark_results.cpp "../bench/core-builds/${remoteref}/src/test/util/"
        cd "../bench/core-builds/${remoteref}/src/"
    fi
    sh build.sh benchmark-common-tasks
    sh build.sh benchmark-crud
    echo "writing results to ${outputfile}"
    # print common header
    head -n 1 "test/benchmark-common-tasks/results.latest.csv" > "${outputfile}"
    # print contents, add _EncryptionOff tag to names without encryption (backwards compatibility)
    tail -n +2 "test/benchmark-common-tasks/results.latest.csv" | perl -wpe "s/^\"(((?!EncryptionO[nf]+).)*)\"/\"\$1_EncryptionOff\"/" >> "${outputfile}"
    tail -n +2 "test/benchmark-crud/results.latest.csv" | perl -wpe "s/^\"(((?!EncryptionO[nf]+).)*)\"/\"\$1_EncryptionOff\"/" >> "${outputfile}"

    if [ "${headref}" != "${remoteref}" ]; then
        cd ../..
        pwd
        echo "cleaning up: ${remoteref}"
        rm -rf "${remoteref}"
    else
        echo "done"
    fi
fi

