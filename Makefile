.PHONY: all


all: dependency build

dependency:
	cd ~
	sudo apt update -y
	sudo apt install gcc make git -y
	git clone https://github.com/vlang/v.git
	cd v
	sudo make
	./v symlink

build:
	/bin/v/v parse.v -o new -prod
	cp new /bin/

clean:
	rm -rf parse
	rm -rf ~/v