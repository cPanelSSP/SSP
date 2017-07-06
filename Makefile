SHELL=/bin/sh
PATH=:/usr/local/cpanel/3rdparty/bin:/usr/sbin:/usr/bin
PERLTIDY=/usr/local/cpanel/3rdparty/perl/524/bin/perltidy
TIDYRC=tools/.perltidyrc
SSP_SHASUM=shasum -a 512 ssp | awk '{print $$1}'
NEW_SSPVER=$(shell grep 'our $$VERSION' ssp | awk '{print $$4}' | sed -e "s/'//g" -e 's/;//')

.DEFAULT: help
.IGNORE: clean
.PHONY: all clean help test tidy
.PRECIOUS: ssp
.SILENT: all help SHA512SUM ssp.tdy test tidy

# A line beginning with a double hash mark is used to provide help text for the target that follows it when running 'make help' or 'make'.  The help target must be first.
# "Invisible" targets should not be marked with help text.

## Show this help
help:
	printf "\nAvailable targets:\n"
	awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "%-15s - %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	printf "\n"

## Make SSP ready for commit
all: SHA512SUM
	
## Clean up
clean:
	$(RM) ssp.tdy

## Add new SSP version to SHA512SUM file
SHA512SUM: tidy
	if ( egrep -q '$(NEW_SSPVER)$$' SHA512SUM ); then \
		echo "Version $(NEW_SSPVER) already exists in SHA512SUM!"; \
		exit 2; \
	else \
		sed -i '1i$(shell $(SSP_SHASUM))    $(NEW_SSPVER)' SHA512SUM && echo "Updated SHA512SUM"; \
	fi

ssp.tdy: ssp
	[ -e $(PERLTIDY) ] || echo "perltidy not found!  Are you running this on a WHM 64+ system?"
	echo "Running tidy..."
	$(PERLTIDY) --profile=$(TIDYRC) ssp

## Run basic tests
test:
	[ -e /usr/local/cpanel/version ] || ( echo "You're not running this on a WHM system."; exit 2 )
	perl -c ssp || ( echo "ssp perl syntax check failed"; exit 2 )

## Run perltidy on ssp, compare, and ask for overwrite
tidy: test ssp.tdy
	if ( diff -u ssp ssp.tdy > /dev/null ); then \
		echo "SSP is tidy."; \
		exit 0; \
	else \
		diff -u ssp ssp.tdy | less -F; \
		cp -i ssp.tdy ssp; \
		if ( diff -u ssp ssp.tdy > /dev/null ); then \
			echo "SSP is tidy."; \
			exit 0; \
		else \
			echo "SSP is NOT tidy."; \
			exit 2; \
		fi; \
	fi;
