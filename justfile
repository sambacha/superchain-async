# Run supersim first then run forge tests
test-forge:
    supersim > /dev/null 2>&1 & sleep 3 && forge test -vv
    pkill -f supersim

test-viem:
    supersim > /dev/null 2>&1 & sleep 3 && yarn test
    pkill -f supersim