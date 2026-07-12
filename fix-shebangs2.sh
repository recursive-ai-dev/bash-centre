file="tests/test_bc_recent_list.sh"
sed -i 's/export BC_RECENT_FILE=$(mktemp)/export BC_RECENT_FILE\nBC_RECENT_FILE=$(mktemp)/g' "$file"
