#!/bin/bash
COMMAND=$(cat | python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" 2>/dev/null)

DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "git push --force"
  "git push -f"
  "DROP TABLE"
  "DROP DATABASE"
  "chmod 777"
  "curl.*| bash"
  "wget.*| bash"
  "sudo rm"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED: Dangerous command pattern detected: $pattern" >&2
    exit 1
  fi
done

exit 0