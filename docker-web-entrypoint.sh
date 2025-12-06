#!/bin/bash -e

# Enable jemalloc for reduced memory usage and latency.
# shellcheck disable=SC2144
if [ -z "${LD_PRELOAD+x}" ] && [ -f /usr/lib/*/libjemalloc.so.2 ]; then
  export LD_PRELOAD="$(echo /usr/lib/*/libjemalloc.so.2)"
fi

# If running the rails server then create or migrate existing database
if [ "${1}" == "./bin/rails" ] && [ "${2}" == "server" ]; then
  ./bin/rails db:prepare

  ./bin/puma
else
  exec "${@}"
fi
