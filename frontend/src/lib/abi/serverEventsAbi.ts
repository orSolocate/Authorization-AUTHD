export const serverEventsAbi = [
  {
    type: 'event',
    anonymous: false,
    name: 'Authorization',
    inputs: [
      { indexed: true, name: 'client', type: 'address' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'authorized', type: 'address' },
      { indexed: false, name: 'amount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    anonymous: false,
    name: 'IncreaseAuthorizedCap',
    inputs: [
      { indexed: true, name: 'client', type: 'address' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'authorized', type: 'address' },
      { indexed: false, name: 'amount', type: 'uint256' },
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
      { indexed: false, name: 'amount', type: 'uint256' },
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
    type: 'event',
    anonymous: false,
    name: 'ApproveFor',
    inputs: [
      { indexed: true, name: 'client', type: 'address' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'authorized', type: 'address' },
      { indexed: false, name: 'amount', type: 'uint256' },
    ],
  },
] as const;
