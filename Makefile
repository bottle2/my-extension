APPLE != pwd
BANANA=~/.mozilla/native-messaging-hosts/ping_pong.json

all:$(BANANA) test

$(BANANA):ping_pong.json
	-mkdir -p ~/.mozilla/native-messaging-hosts
	sed 's|REPL|$(APPLE)|' < ping_pong.json > $(BANANA)

test:test.c
	cc -DREPL='"$(APPLE)/debug.txt"' -Wpedantic -Wall -Wextra test.c -o test
