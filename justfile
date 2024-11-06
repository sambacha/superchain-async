# Run supersim first then run forge tests
test-forge:
    supersim > /dev/null 2>&1 & sleep 3 && forge test -vv
    pkill -f supersim

test-viem:
    supersim --log.level DEBUG --log.format terminal --logs.directory logs --interop.autorelay & sleep 3 && yarn test
    pkill -f supersim

promify file:
    python3 scripts/promify_contracts.py --file {{file}}