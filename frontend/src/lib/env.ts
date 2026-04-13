const required = (name: string, value: string | undefined) => {
  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }
  return value;
};

export const env = {
  walletConnectProjectId: required(
    'VITE_WALLETCONNECT_PROJECT_ID',
    import.meta.env.VITE_WALLETCONNECT_PROJECT_ID,
  ),
  sepoliaRpcUrl: required('VITE_SEPOLIA_RPC_URL', import.meta.env.VITE_SEPOLIA_RPC_URL),
  customClientAddress: required(
    'VITE_CUSTOM_CLIENT_ADDRESS',
    import.meta.env.VITE_CUSTOM_CLIENT_ADDRESS,
  ) as `0x${string}`,
  serverAddress: required('VITE_SERVER_ADDRESS', import.meta.env.VITE_SERVER_ADDRESS) as `0x${string}`,
};
