'use client'

import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import TokenBankABI from './abi/TokenBank.json'
import ERC20ABI from './abi/ERC20.json'
import Permit2ABI from './abi/Permit2.json'
import { useAccount, useConnect, useDisconnect, useChainId } from 'wagmi'
import { injected } from 'wagmi/connectors'

export default function Home() {
  // Contract addresses
  const BANK_ADDRESS = '0xdB3eF3cB3079C93A276A2B4B69087b8801727f64'
  const TOKEN_ADDRESS = '0xe4Cec63058807C50C95CEF99b0Ab5A9831610386'
  const PERMIT2_ADDRESS = '0x000000000022D473030F116dDEE9F6B43aC78BA3'

  // State variables
  const [amount, setAmount] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [mounted, setMounted] = useState(false)

  // Wagmi hooks
  const { address, isConnected } = useAccount()
  const { connect } = useConnect()
  const { disconnect } = useDisconnect()
  const chainId = useChainId()

  // Handle client-side mounting
  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return null // or return a loading indicator
  }

  // Handle deposit with permit2
  const handleDepositWithPermit2 = async () => {
    try {
      setLoading(true)
      setError('')
      setSuccess('')

      if (!window?.ethereum) throw new Error('Please install MetaMask')
      if (!address) throw new Error('Please connect your wallet')

      const provider = new ethers.providers.Web3Provider(window.ethereum as any)
      const signer = provider.getSigner()

      // Create contract instances
      const bankContract = new ethers.Contract(BANK_ADDRESS, TokenBankABI, signer)
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, ERC20ABI, signer)
      const permit2Contract = new ethers.Contract(PERMIT2_ADDRESS, Permit2ABI, signer)

      // Convert amount to wei
      const amountWei = ethers.utils.parseEther(amount)

      // Get nonce
      const wordPos = 0
      const bitmap = await permit2Contract.nonceBitmap(address, wordPos)
      const nonce = await findNextNonce(bitmap, wordPos)

      // Set deadline to 1 hour from now
      const deadline = Math.floor(Date.now() / 1000) + 3600

      // Create permit message
      const domain = {
        name: 'Permit2',
        chainId: chainId,
        verifyingContract: PERMIT2_ADDRESS
      }

      const types = {
        PermitTransferFrom: [
          { name: 'permitted', type: 'TokenPermissions' },
          { name: 'spender', type: 'address' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' }
        ],
        TokenPermissions: [
          { name: 'token', type: 'address' },
          { name: 'amount', type: 'uint256' }
        ]
      }

      const value = {
        permitted: {
          token: TOKEN_ADDRESS,
          amount: amountWei
        },
        spender: BANK_ADDRESS,
        nonce: nonce,
        deadline: deadline
      }

      // Get signature
      const signature = await signer._signTypedData(domain, types, value)

      // Execute deposit
      const tx = await bankContract.depositWithPermit2(
        amountWei,
        nonce,
        deadline,
        signature
      )

      await tx.wait()
      setSuccess('Deposit successful!')
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  // Helper function to find next nonce
  const findNextNonce = (bitmap: ethers.BigNumber, wordPos: number) => {
    for (let bit = 0; bit < 256; bit++) {
      if (!(bitmap.and(ethers.BigNumber.from(1).shl(bit)).gt(0))) {
        return ethers.BigNumber.from(wordPos).shl(8).or(bit)
      }
    }
    throw new Error('No available nonce found')
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm">
        <h1 className="text-4xl font-bold mb-8">TokenBank Deposit</h1>
        
        {!isConnected ? (
          <button
            onClick={() => connect({ connector: injected() })}
            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Connect Wallet
          </button>
        ) : (
          <div className="space-y-4">
            <p>Connected: {address}</p>
            <div>
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="Amount to deposit"
                className="border p-2 rounded mr-2 bg-gray-800 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <button
                onClick={handleDepositWithPermit2}
                disabled={loading}
                className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
              >
                {loading ? 'Processing...' : 'Deposit with Permit2'}
              </button>
            </div>
            {error && <p className="text-red-500">{error}</p>}
            {success && <p className="text-green-500">{success}</p>}
            <button
              onClick={() => disconnect()}
              className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
            >
              Disconnect
            </button>
          </div>
        )}
      </div>
    </main>
  )
}
