#!/bin/bash

set -eo pipefail

cd "$(dirname "$(find . -name 'go.mod' | head -n 1)")" || exit 1
echo PWD
pwd
MODULE_ROOT="$(go list -m)"
echo MODULE_ROOT - $MODULE_ROOT
REPO_NAME="$(basename $(echo $GITHUB_REPOSITORY))"
echo GITHUB_REPOSITORY - $GITHUB_REPOSITORY
echo REPO_NAME - $REPO_NAME
PR_NUMBER="$(echo $GITHUB_REF | sed 's#refs/pull/\(.*\)/.*#\1#')"
echo GITHUB_REF - $GITHUB_REF
echo PR_NUMBER - $PR_NUMBER

mkdir -p "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
echo mkdir "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
cp -r * "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
echo COPY
ls -lR "$GOPATH/src/github.com/$GITHUB_REPOSITORY"

(cd "$GOPATH/src/github.com/$GITHUB_REPOSITORY" && godoc -http localhost:8080 &)

for (( ; ; )); do
  echo SLEEP
  sleep 0.5
  if [[ $(curl -so /dev/null -w '%{http_code}' "http://localhost:8080/pkg/$MODULE_ROOT/") -eq 200 ]]; then
    break
  fi
done

echo git config
git config --global --add safe.directory '*'
echo git checkout origin/gh-pages
git checkout origin/gh-pages || git checkout -b gh-pages
echo git checkout origin/gh-pages - done

wget --quiet --mirror --show-progress --page-requisites --execute robots=off --no-parent "http://localhost:8080/pkg/$MODULE_ROOT/"

rm -rf doc lib "$PR_NUMBER" # Delete previous documents.
mv localhost:8080/* .
rm -rf localhost:8080
find pkg -type f -exec sed -i "s#/lib/godoc#/$REPO_NAME/lib/godoc#g" {} +

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
[ -d "$PR_NUMBER" ] || mkdir "$PR_NUMBER"
mv pkg "$PR_NUMBER"
git add "$PR_NUMBER" doc lib
git commit -m "Update documentation"

GODOC_URL="https://$(dirname $(echo $GITHUB_REPOSITORY)).github.io/$REPO_NAME/$PR_NUMBER/pkg/$MODULE_ROOT/index.html"

if ! curl -sH "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" | grep '## GoDoc' > /dev/null; then
  curl -sH "Authorization: token $GITHUB_TOKEN" \
    -d '{ "body": "## GoDoc\n'"$GODOC_URL"'" }' \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments"
fi
