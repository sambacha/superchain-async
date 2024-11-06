import { expect, test } from 'vitest'
import { clientA, clientB, walletA, walletB } from './helpers'

test('Sanity check supersim chainIDs and balances', async () => {
    const chainIdA = await clientA.getChainId() 
    expect(chainIdA).toBe(901)

    const chainIdB = await clientB.getChainId() 
    expect(chainIdB).toBe(902)

    const walletAddressA = await walletA.getAddresses()
    const walletAddressB = await walletB.getAddresses()

    const balanceA = await clientA.getBalance({address: walletAddressA[0]})
    const balanceB = await clientB.getBalance({address: walletAddressB[0]})
    
    // should be nonzero
    expect(balanceA).toBeGreaterThan(0)
    expect(balanceB).toBeGreaterThan(0)
}) 