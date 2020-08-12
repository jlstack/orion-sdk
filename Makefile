DIRS = Communications Utils Examples

build:
	@for x in $(DIRS); do make -C $$x build; done

clean:
	@for x in $(DIRS); do make -C $$x clean; done; rm -rf Communications/x86/ Communications/aarch64/ Utils/x86/ Utils/aarch64/
