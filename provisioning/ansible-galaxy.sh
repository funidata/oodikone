#!/usr/bin/env bash

set -ue

if [ -n "$GITHUB_TOKEN_FILE" ]; then
    GITHUB_TOKEN="$(cat $GITHUB_TOKEN_FILE)"
fi

git config --global user.name $GITHUB_USERNAME
git config --global credential.helper 'store'
git config --global credentials."https://github.com".username $GITHUB_USERNAME
git config --global url."https://github.com/".insteadOf "git@github.com:"

cat > ~/.git-credentials <<EOF
https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com
EOF

# retry wrapper for collection install failures
for i in {5..1}; do
    if ansible-galaxy "$@"; then
        break
    elif [ $i -gt 1 ]; then
        sleep 1
    else
        exit 1
    fi
done
