.PHONY: lint test install-hooks demo

lint:
	luacheck lua/ tests/

test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ {sequential = true}"

install-hooks:
	@printf '#!/bin/sh\nmake lint\n' > .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed. Run 'make lint' to check manually."

demo:
	demo/record.sh
