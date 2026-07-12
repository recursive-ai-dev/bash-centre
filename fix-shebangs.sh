#!/usr/bin/env bash

# Fix examples
for file in examples/*.sh; do
  if ! head -n 1 "$file" | grep -q "^#!"; then
    temp=$(mktemp)
    echo "#!/usr/bin/env bash" > "$temp"
    cat "$file" >> "$temp"
    mv "$temp" "$file"
    chmod +x "$file"
  fi
done

# Fix test script
file="tests/test_bc_recent_list.sh"
temp=$(mktemp)
sed 's/fails=0/local fails=0/g' "$file" > "$temp" || true
# actually it's global fails=0. SC2155 is "Declare and assign separately"

# The SC2155 warning is in tests/test_bc_recent_list.sh:27:8
sed -i 's/export BC_RECENT_FILE=$(mktemp)/export BC_RECENT_FILE\nBC_RECENT_FILE=$(mktemp)/g' "$file"
