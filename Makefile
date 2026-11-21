.PHONY: build dev release install-dev install-release uninstall

build:
	swift build

dev:
	./scripts/bundle.sh debug

release:
	./scripts/bundle.sh release

install-dev:
	./scripts/install.sh debug

install-release:
	./scripts/install.sh release

uninstall:
	./scripts/uninstall.sh
