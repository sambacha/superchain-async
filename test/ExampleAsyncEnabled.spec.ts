import { expect, test } from 'vitest'
import { chainA, chainB, clientA, clientB, walletA, walletB, deployAndGetContract, sleep } from './helpers'
import ExampleAsyncEnabled from '../out/ExampleAsyncEnabled.sol/ExampleAsyncEnabled.json'

test('MyCoolAsync callback loop', async () => {
    const returnValA = 420n
    const returnValB = 69n

    const exampleAsyncEnabledA = await deployAndGetContract(ExampleAsyncEnabled, [returnValA], walletA, clientA)
    const exampleAsyncEnabledB = await deployAndGetContract(ExampleAsyncEnabled, [returnValB], walletB, clientB)

    await exampleAsyncEnabledA.write.makeAsyncCallAndStore([exampleAsyncEnabledB.address, chainB.id])

    await sleep(10000)

    expect(await exampleAsyncEnabledA.read.lastValueReturned()).toBe(returnValB)
})
