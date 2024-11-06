import { expect, test } from 'vitest'
import { chainA, chainB, clientA, clientB, walletA, walletB } from './helpers'
import { getContract } from 'viem'
import MyAsyncEnabled from '../out/MyAsyncEnabled.sol/MyAsyncEnabled.json'
import { PublicClient } from 'viem'

// const deployMyAsyncEnabled = async(client: PublicClient) => {
//     const myAsyncEnabled = await client.deployContract({
//         abi: MyAsyncEnabled.abi,
//         bytecode: MyAsyncEnabled.bytecode.object,
//     })

//     return getContract(
//       myAsyncEnabled
//     )
// }

test('MyCoolAsync callback loop', async () => {
    const myAsyncEnabledA = await walletA.deployContract({
        abi: MyAsyncEnabled.abi,
        bytecode: MyAsyncEnabled.bytecode.object,
    })

    const myAsyncEnabledB = await walletB.deployContract({
        abi: MyAsyncEnabled.abi,
        bytecode: MyAsyncEnabled.bytecode.object,
    })

    // log both addresses
    console.log(myAsyncEnabledA)
    console.log(myAsyncEnabledB)

    await myAsyncEnabledA.write.doLoop1({
        args: [chainB.id],
    })

    console.log(myAsyncEnabledA)
})