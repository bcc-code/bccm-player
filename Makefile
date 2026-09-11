.PHONY: publish pigeons help ios-test

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

# Which simulator the native iOS tests run on. Defaults to the newest available
# iPhone, so this works on a dev machine and on a CI runner with a different
# set of runtimes installed. Override with either:
#   make ios-test IOS_SIM_ID=<udid>
#   make ios-test IOS_DESTINATION='platform=iOS Simulator,name=iPhone 16,OS=latest'
IOS_SIM_ID ?= $(shell xcrun simctl list devices available | awk '/^-- iOS /{ok=1; next} /^-- /{ok=0} ok && /iPhone/{l=$$0} END{print l}' | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
IOS_DESTINATION ?= id=$(IOS_SIM_ID)

ios-test: ## Run the native iOS unit tests (example/ios/RunnerTests) on a simulator
	@test -n "$(IOS_SIM_ID)" || (echo "No iPhone simulator available. Install one via Xcode > Settings > Components."; exit 1)
	cd example && flutter pub get && flutter build ios --simulator --debug --config-only
	cd example/ios && xcodebuild test \
		-workspace Runner.xcworkspace \
		-scheme Runner \
		-destination '$(IOS_DESTINATION)' \
		-only-testing:RunnerTests
