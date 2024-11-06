// config.ts
import { createTestClient, http, createWalletClient, createPublicClient, getContract } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { defineChain } from 'viem'

export const chainA = defineChain({
    id: 901,
    name: 'interopChainA',
    nativeCurrency: {
      decimals: 18,
      name: 'Ether',
      symbol: 'ETH',
    },
    rpcUrls: {
      default: {
        http: ['http://127.0.0.1:9545'],
      },
    },
    blockExplorers: {
      default: { name: 'Explorer', url: 'https://deez.nuts' },
    },
})

export const chainB = defineChain({
    id: 902,
    name: 'interopChainB',
    nativeCurrency: {
      decimals: 18,
      name: 'Ether',
      symbol: 'ETH',
    },
    rpcUrls: {
      default: {
        http: ['http://127.0.0.1:9546'],
      },
    },
    blockExplorers: {
      default: { name: 'Explorer', url: 'https://deez.nuts' },
    },
})

export const account = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")

export const clientA = createPublicClient({
    chain: chainA,
    transport: http(),
})

export const clientB = createPublicClient({
    chain: chainB,
    transport: http(),
})

export const walletA = createWalletClient({
    account,
    transport: http(),
    chain: chainA
})

export const walletB = createWalletClient({
    account,
    transport: http(),
    chain: chainB
})

export const deployAndGetContract = async (wallet: Wallet, client: PublicClient, contractImport: any) => {
    const deployTxHash = await wallet.deployContract({
        abi: contractImport.abi,
        bytecode: contractImport.bytecode.object,
    })

    await client.waitForTransactionReceipt({
        hash: deployTxHash,
    })

    const receipt = await client.getTransactionReceipt({
        hash: deployTxHash,
    })

    if (!receipt.contractAddress) {
        throw new Error("Contract address undefined")
    }

    return getContract({
        address: receipt.contractAddress,
        abi: contractImport.abi,
        client: wallet,
    })
}