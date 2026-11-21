.PHONY: build dev release release-dmg notarize-dmg install-dev install-release uninstall

build:
	swift build

dev:
	./scripts/bundle.sh debug

release:
	./scripts/bundle.sh release

release-dmg:
	./scripts/release-dmg.sh

notarize-dmg:
	./scripts/notarize-dmg.sh

install-dev:
	./scripts/install.sh debug

install-release:
	./scripts/install.sh release

uninstall:
	./scripts/uninstall.sh
