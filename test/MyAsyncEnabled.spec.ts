import { expect, test } from 'vitest'
import { createPublicClient, http, createWalletClient } from 'viem'

const transportA = http("HTTP://127.0.0.1:9545")
const transportB = http("HTTP://127.0.0.1:9546")

const clientA = createPublicClient({
  transport: transportA,
})

const clientB = createPublicClient({
  transport: transportB,
})

const walletA = createWalletClient({
    account: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    transport: transportA,
})

const walletB = createWalletClient({
    account: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    transport: transportB,
})

test('Sanity check supersim chainIDs and balances', async () => {
    const chainIdA = await clientA.getChainId() 
    console.log(chainIdA)
    expect(chainIdA).toBe(901)

    const chainIdB = await clientB.getChainId() 
    console.log(chainIdB)
    expect(chainIdB).toBe(902)

    const walletAddressA = await walletA.getAddresses()
    const walletAddressB = await walletB.getAddresses()

    const balanceA = await clientA.getBalance({address: walletAddressA[0]})
    const balanceB = await clientB.getBalance({address: walletAddressB[0]})
    
    // should be nonzero
    expect(balanceA).toBeGreaterThan(0)
    expect(balanceB).toBeGreaterThan(0)
})