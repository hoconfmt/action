#!/bin/bash
set -e
if [ -n "$DEBUG$RUNNER_DEBUG" ] || [ $GITHUB_RUN_ATTEMPT != 1 ]; then
  set -x
fi

echo "::add-matcher::$GITHUB_ACTION_PATH/match-syntax.json"

is_number() {
  [ "$1" -eq "$1" ] 2>/dev/null
}

job_count="${PARALLEL_TASKS}"
if [ -z "$job_count" ]; then
  job_count=$(nproc 2>/dev/null || sysctl -n hw.physicalcpu)
fi
if ! is_number "$job_count" || [ $job_count -lt 2 ]; then
  job_count=1
fi

if [ -z "$FILES" ] && [ ! -s "$LIST" ]; then
  echo "No files configured" >&2
  exit 1
fi

errors=$(mktemp)

(
  for file in $FILES; do
    printf "$file\0"
  done

  if [ -n "$LIST" ]; then
    cat "$LIST"
  fi
) | xargs -P ${job_count} -0 -n1 $GITHUB_WORKSPACE/../hoconfmt --write --commas commas

: Report
files=$(mktemp)
git ls-files -m > "$files"
file_size=$(stat -c %s "$files" 2>/dev/null || stat -f %z "$files")
if [ $file_size = 0 ]; then
  exit 0
fi
diff=$(mktemp)
git diff > "$diff"
if [ -z "$SKIP_SUMMARY" ]; then
  (
    echo '# hocon format'
    if [ $file_size -gt 1000000000 ]; then
      echo "Diff is too big, please check the artifact instead"
    else
      warnings=$(mktemp)
      ($GITHUB_ACTION_PATH/check-diff.pl "$diff" 2>&1) > "$warnings"
      needs_advice=
      if grep -q 'windows line endings' "$warnings"; then
        echo 'Found Windows line endings in diff.'
        echo "Unfortunately, GitHub's Step Summary feature mangles Windows line ending output."
        needs_advice=1
      fi
      if grep -q 'mixed line endings' "$warnings"; then
        echo 'Found mixed line endings in diff.'
        needs_advice=1
      fi
      if [ -n "$needs_advice" ]; then
        echo 'You will probably need to download the artifact:'
        echo '* It contains a patch file that you can try to apply.'
        echo '* It contains the fixed files and you can copy them over your originals.'
        echo
      fi
      echo '```diff'
      cat "$diff"
      echo
      echo '```'
      if [ -s "$warnings" ]; then
        echo
        perl -pe 's/^/::warning ::/' "$warnings" >&2
      fi
    fi
  ) | tee -a "$GITHUB_STEP_SUMMARY"
fi

marker=$(shasum "$files")
hash=$(echo "$marker$MATRIX" | shasum -)
id=${hash%% *}
cp "$diff" "$id.patch"
echo "$id.patch" >> "$files"

(
  echo "id=$id"
  echo "files<<$marker"
  cat "$files"
  echo "$marker"
) >> "$GITHUB_OUTPUT"
