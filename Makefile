APPLE != pwd
BANANA=~/.mozilla/native-messaging-hosts/ping_pong.json

all:$(BANANA) test background.js

$(BANANA):ping_pong.json
	-mkdir -p ~/.mozilla/native-messaging-hosts
	sed 's|REPL|$(APPLE)|' < ping_pong.json > $(BANANA)

background.js:background.c
	emcc -sEXPORTED_FUNCTIONS=_free,_main -sEXPORTED_RUNTIME_METHODS=stringToNewUTF8,UTF8ToString -Wpedantic -Wall -Wextra -Oz -flto background.c -o background.js

background.c:background.rl
	ragel -G2 background.rl

test.c:test.rl
	ragel -G2 test.rl

test:test.c
	cc -DREPL='"$(APPLE)/debug.txt"' -Wpedantic -Wall -Wextra -Wno-implicit-fallthrough -Wshadow -O2 -flto test.c -o test
