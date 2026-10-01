.PHONY: all app cli dmg setup install run clean

all:
	./Scripts/build.sh

app:
	./Scripts/build.sh

cli:
	./Scripts/build.sh

dmg:
	./Scripts/package_dmg.sh

setup:
	./Scripts/setup_and_build.sh

install: all
	@echo "📲 Installing to /Applications..."
	@rm -rf "/Applications/LG Control.app"
	@cp -R "build/LG Control.app" "/Applications/LG Control.app"
	@echo "🔗 Setting up CLI symlink..."
	@if [ -d "/opt/homebrew/bin" ]; then \
		ln -sf "$$(pwd)/bin/lg-control" "/opt/homebrew/bin/lg-control"; \
		echo "✅ Symlinked to /opt/homebrew/bin/lg-control"; \
	elif [ -d "/usr/local/bin" ]; then \
		ln -sf "$$(pwd)/bin/lg-control" "/usr/local/bin/lg-control"; \
		echo "✅ Symlinked to /usr/local/bin/lg-control"; \
	fi
	@echo "🎉 Installation complete! You can open 'LG Control' from Launchpad or Applications."

run:
	open "build/LG Control.app"

clean:
	rm -rf build bin
