#!/usr/bin/env bash
# import_tau_cache.sh — copy τ-cache fixtures from a source project's
# data/tau_cache into this repo's precision-first, λ²-then-nmodes-bucket
# layout. Handles both single .json.zip and byte-split .json.zip.partXX.
#
#   SRC=/path/to/project/data/tau_cache bash import_tau_cache.sh
#
# Idempotent: re-importing the same file is a no-op dedup (identical
# content for a given (λ²,N,prec)).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST_ROOT="$REPO_ROOT/tau_cache"
SRC="${SRC:?set SRC to the source data/tau_cache dir}"

if [[ ! -d "$SRC" ]]; then
  echo "ERROR: SRC=$SRC not found" >&2
  exit 1
fi

copied=0
skipped=0
for f in "$SRC"/*.json.zip "$SRC"/*.json.zip.part*; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f")"   # lambda_sq{L}_nmodes{N}_prec{P}.json.zip[.partXX]
  # Parse L, N, P from the canonical filename (ignore any .zip/.partXX tail).
  if [[ "$base" =~ ^lambda_sq([0-9]+)_nmodes([0-9]+)_prec([0-9]+)\.json\.zip ]]; then
    L="${BASH_REMATCH[1]}"
    N="${BASH_REMATCH[2]}"
    P="${BASH_REMATCH[3]}"
  else
    echo "  SKIP (unrecognized name): $base" >&2
    skipped=$((skipped+1))
    continue
  fi
  bucket=$(( (N / 1000) * 1000 ))
  dir="$DEST_ROOT/prec${P}/lambda_sq${L}/nmodes${bucket}-$((bucket+999))"
  mkdir -p "$dir"
  if [[ -e "$dir/$base" ]]; then
    skipped=$((skipped+1))
  else
    cp "$f" "$dir/$base"
    copied=$((copied+1))
  fi
done

echo "imported: $copied new, $skipped skipped (already present / unrecognized)"
echo "dest precision folders:"
find "$DEST_ROOT" -maxdepth 1 -type d | sort | sed "s|$DEST_ROOT|tau_cache|"
