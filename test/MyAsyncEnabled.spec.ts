import { expect, test } from 'vitest'
import { chainA, chainB, clientA, clientB, walletA, walletB, deployAndGetContract } from './helpers'
import MyAsyncEnabled from '../out/MyAsyncEnabled.sol/MyAsyncEnabled.json'

test('MyCoolAsync callback loop', async () => {
    const myAsyncEnabledA = await deployAndGetContract(walletA, clientA, MyAsyncEnabled)

    const myAsyncEnabledB = await deployAndGetContract(walletB, clientB, MyAsyncEnabled)

    await myAsyncEnabledA.write.doLoop1([chainB.id, myAsyncEnabledB.address])
})