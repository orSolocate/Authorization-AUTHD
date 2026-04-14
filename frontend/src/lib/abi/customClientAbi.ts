// ALL authorization calls go through the CUSTOM CLIENT contract (0x610d...)
// msg.sender is used as owner/authorized internally — no need to pass it explicitly
export const customClientAbi = [
  // ── ERC20 views ──────────────────────────────────────────────────────────
  {
    type: 'function',
    stateMutability: 'view',
    name: 'name',
    inputs: [],
    outputs: [{ name: '', type: 'string' }],
  },
  {
    type: 'function',
    stateMutability: 'view',
    name: 'symbol',
    inputs: [],
    outputs: [{ name: '', type: 'string' }],
  },
  {
    type: 'function',
    stateMutability: 'view',
    name: 'decimals',
    inputs: [],
    outputs: [{ name: '', type: 'uint8' }],
  },
  {
    type: 'function',
    stateMutability: 'view',
    name: 'balanceOf',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },

  // ── Registration ─────────────────────────────────────────────────────────
  {
    type: 'function',
    stateMutability: 'view',
    name: 'getRegistrationFee',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    type: 'function',
    stateMutability: 'view',
    name: 'isRegisteredClient',
    inputs: [],
    outputs: [{ name: '', type: 'bool' }],
  },
  {
    type: 'function',
    stateMutability: 'payable',
    name: 'registerClient',
    inputs: [],
    outputs: [],
  },
  {
    type: 'function',
    stateMutability: 'nonpayable',
    name: 'buyTokens',
    inputs: [{ name: 'amount', type: 'uint256' }],
    outputs: [],
  },

  // ── Authorization — all 2-arg, msg.sender = owner ─────────────────────────
  {
    // authorize(authorized, cap) — 0xc1dbd9b2
    type: 'function',
    stateMutability: 'nonpayable',
    name: 'authorize',
    inputs: [
      { name: 'authorized', type: 'address' },
      { name: 'cap', type: 'uint256' },
    ],
    outputs: [],
  },
  {
    // increaseAuthorizedCap(authorized, addedCap) — 0xdea3841b
    type: 'function',
    stateMutability: 'nonpayable',
    name: 'increaseAuthorizedCap',
    inputs: [
      { name: 'authorized', type: 'address' },
      { name: 'addedCap', type: 'uint256' },
    ],
    outputs: [{ name: 'newCap', type: 'uint256' }],
  },
  {
    // decreaseAuthorizedCap(authorized, subtractedCap) — 0x5f207bb8
    type: 'function',
    stateMutability: 'nonpayable',
    name: 'decreaseAuthorizedCap',
    inputs: [
      { name: 'authorized', type: 'address' },
      { name: 'subtractedCap', type: 'uint256' },
    ],
    outputs: [{ name: 'newCap', type: 'uint256' }],
  },
  {
    // revokeAuthorization(authorized) — 0xb48028e3
    type: 'function',
    stateMutability: 'nonpayable',
    name: 'revokeAuthorization',
    inputs: [{ name: 'authorized', type: 'address' }],
    outputs: [],
  },
  {
    // approveFor(owner, spender, amount) — 0x2b991746 — called by authorized delegate
    type: 'function',
    stateMutability: 'nonpayable',
    name: 'approveFor',
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
  },

  // ── Custom errors ─────────────────────────────────────────────────────────
  { type: 'error', name: 'AlreadyAuthorized', inputs: [{ name: 'client', type: 'address' }, { name: 'owner', type: 'address' }, { name: 'authorized', type: 'address' }] },
  { type: 'error', name: 'AlreadyRegistered', inputs: [{ name: 'client', type: 'address' }] },
  { type: 'error', name: 'ClientNotRegistered', inputs: [{ name: 'client', type: 'address' }] },
  { type: 'error', name: 'InsufficientAuthorizedCap', inputs: [{ name: 'client', type: 'address' }, { name: 'owner', type: 'address' }, { name: 'authroized', type: 'address' }, { name: 'currentCap', type: 'uint256' }, { name: 'amountRequested', type: 'uint256' }] },
  { type: 'error', name: 'InsufficientOwnerBalance', inputs: [{ name: 'client', type: 'address' }, { name: 'owner', type: 'address' }, { name: 'capAmount', type: 'uint256' }] },
  { type: 'error', name: 'InsufficientRegistrationFee', inputs: [{ name: 'providedFee', type: 'uint256' }, { name: 'registerationFee', type: 'uint256' }] },
  { type: 'error', name: 'InvalidAmount', inputs: [{ name: 'amount', type: 'uint256' }] },
  { type: 'error', name: 'InvalidSpender', inputs: [{ name: 'spender', type: 'address' }] },
  { type: 'error', name: 'NotCurrentlyAuthorized', inputs: [{ name: 'client', type: 'address' }, { name: 'owner', type: 'address' }, { name: 'authorized', type: 'address' }] },
  { type: 'error', name: 'SelfAuthorizationProhibited', inputs: [] },
] as const;