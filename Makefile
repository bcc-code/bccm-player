.PHONY: publish pigeons help

BUILD_NUMBER=$(shell grep -i -e "version: " pubspec.yaml | cut -d " " -f 2)

# From https://stackoverflow.com/a/64996042
help:
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'


publish: ## Publish the package to pub.dev
	read -p "Release v${BUILD_NUMBER}? (CTRL+C to abort)"
	git tag v${BUILD_NUMBER}
	git push origin v${BUILD_NUMBER}
	dart pub publish
	mkdocs gh-deploy

pigeons: ## Generate pigeon files
	for f in pigeons/*.dart; do dart run pigeon --input $$f; done