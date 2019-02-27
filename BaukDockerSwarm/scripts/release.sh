#!/usr/bin/env sh

set -e
printf "
            RELEASING
           ===========
"

OLD_VERSION=$(git tag | sort -V | tail)
if [[ ! "$(echo $OLD_VERSION | grep '^\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)$')" ]]
then
    printf "
        ERROR: INVALID OLD VERSION FOUND: '$OLD_VERSION'
    \n"
    exit 1
fi
if [[ "$(git status -s)" ]]
then
    printf "
        ERROR: Cannot release with items in staging area!
    \n"
    exit 1
fi

OLD_MAJOR=$(echo $OLD_VERSION | sed "s/^\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)$/\1/g")
OLD_MINOR=$(echo $OLD_VERSION | sed "s/^\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)$/\2/g")
OLD_PATCH=$(echo $OLD_VERSION | sed "s/^\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)$/\3/g")
(( NEW_PATCH = OLD_PATCH + 1 ))

export VERSION="${OLD_MAJOR}.${OLD_MINOR}.${NEW_PATCH}"

printf "
    USING VERSION: $VERSION
    USING MESSAGE: '$@'

"
git tag $VERSION -m "$@"
git push --tags
./scripts/build.sh
docker-compose -f docker-compose.yaml -f docker-compose-build.yaml push
