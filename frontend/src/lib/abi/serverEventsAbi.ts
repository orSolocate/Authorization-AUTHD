export const serverEventsAbi = [
  {
    // topic: 0xede87e9876630140ad0c9c48ac9eb24f60bc571910e448bfbe9b42581f4b4a0d
    type: 'event',
    anonymous: false,
    name: 'Authorization',
    inputs: [
      { indexed: true, name: 'client', type: 'address' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'authorized', type: 'address' },
      { indexed: false, name: 'cap', type: 'uint256' },
    ],
  },
  {
    // topic: 0x8a2d27439e1d41db8aa6a37498dcc08f5d8e6742f25c421d8d01df97ded710f7
    type: 'event',
    anonymous: false,
    name: 'IncreaseAuthorizedCap',
    inputs: [
      { indexed: true, name: 'client', type: 'address' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'authorized', type: 'address' },
      { indexed: false, name: 'newCap', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    anonymous: false,
    name: 'DecreaseAuthorizedCap',
    inputs: [
      { indexed: true, name: 'client', type: 'address' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'authorized', type: 'address' },
      { indexed: false, name: 'newCap', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    anonymous: false,
    name: 'RevokeAuthorization',
    inputs: [
      { indexed: true, name: 'client', type: 'address' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'authorized', type: 'address' },
    ],
  },
  {
    // ApproveFor has: authorized, spender, approvedAmount (3 non-indexed fields)
    type: 'event',
    anonymous: false,
    name: 'ApproveFor',
    inputs: [
      { indexed: true, name: 'client', type: 'address' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'authorized', type: 'address' },
      { indexed: false, name: 'spender', type: 'address' },
      { indexed: false, name: 'approvedAmount', type: 'uint256' },
    ],
  },
] as const;