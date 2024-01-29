
build:
	xcodebuild clean build

deploy: build
	sudo rm -rf /Applications/EasyChapters.app
	sudo cp -rf ./build/Release/EasyChapters.app /Applications

.PHONY: build

%:
	@:
