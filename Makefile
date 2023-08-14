.PHONY: publish

BUILD_NUMBER=$(shell grep -i -e "version: " pubspec.yaml | cut -d " " -f 2)

publish:
	read -p "Release v${BUILD_NUMBER}? (CTRL+C to abort)"
	git tag v${BUILD_NUMBER}
	git push origin v${BUILD_NUMBER}
	dart pub publish
	mkdocs gh-deploy