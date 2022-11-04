# Common set of functions
# Error check is done with set -e command . Build will fail if any of the commands fail

# Variables expected from CI - PULL_NUMBER , JOB_TYPE , ARTIFACTS
set -x

# Initialize & Build  docs
build_docs() {
	apk --update add autoconf automake build-base libtool nasm pkgconf git
	make initialize
	GATSBY_APPZI_TOKEN=${GATSBY_APPZI_TOKEN} GATSBY_ALGOLIA_APP_ID=${GATSBY_ALGOLIA_APP_ID} GATSBY_ALGOLIA_SEARCH_KEY=${GATSBY_ALGOLIA_SEARCH_KEY} ALGOLIA_ADMIN_KEY=${ALGOLIA_ADMIN_KEY} make build
}

# Run Vale on the content folder
check_docs() {
	VERSION=2.21.0
	wget https://github.com/errata-ai/vale/releases/download/v$VERSION/vale_${VERSION}_Linux_64-bit.tar.gz
	mkdir bin && tar -xvzf vale_${VERSION}_Linux_64-bit.tar.gz -C bin
	export PATH=./bin:"$PATH"
	vale sync
	# Run Vale against all modified files in the current commit
	vale $(git diff-tree -r --no-commit-id --name-only $PULL_PULL_SHA | grep content) 
}

# Initialize & Build  release docs
build_release_docs() {
	apk --update add autoconf automake build-base libtool nasm pkgconf
	make initialize
	GATSBY_FULLSTORY_TOKEN=${REL_GATSBY_FULLSTORY_TOKEN} GATSBY_ALGOLIA_APP_ID=${REL_GATSBY_ALGOLIA_APP_ID} GATSBY_ALGOLIA_SEARCH_KEY=${REL_GATSBY_ALGOLIA_SEARCH_KEY} ALGOLIA_ADMIN_KEY=${REL_ALGOLIA_ADMIN_KEY} make build
}

# Sync docs to s3
sync_s3() {
	aws s3 sync --cache-control 'max-age=604800' --exclude '*.html' --exclude '*page-data/*' --exclude '*.txt' --exclude '*.xml' --exclude '*/sw.js' public/ s3://docs-latest.spectrocloud.com --delete
	aws s3 sync --cache-control 'max-age=0, s-maxage=604800' public/ s3://docs-latest.spectrocloud.com --delete
	aws cloudfront create-invalidation --distribution-id EV0DH5A7CFZBY --paths "/*"
	return 0
}

# Sync docs to docs
sync_s3_release() {
        rm -f public/robots.txt
	aws s3 sync --cache-control 'max-age=604800' --exclude '*.html' --exclude '*page-data/*' --exclude '*.txt' --exclude '*.xml' --exclude '*/sw.js' public/ s3://docs.spectrocloud.com --delete
	aws s3 sync --cache-control 'max-age=0, s-maxage=604800' public/ s3://docs.spectrocloud.com --delete
	aws cloudfront create-invalidation --distribution-id E1LK6TRNPR90DX --paths "/*"
	return 0
}
