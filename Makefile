DIRS = Communications Utils Examples

build:
	@for x in $(DIRS); do make -C $$x build; done

clean:
	@for x in $(DIRS); do make -C $$x clean; done; rm -rf x86/ aarch64/
