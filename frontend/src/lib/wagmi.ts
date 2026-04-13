import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'wagmi';
import { appChain } from './chain';
import { env } from './env';

export const wagmiConfig = getDefaultConfig({
  appName: 'ERC20 Authorized Demo',
  projectId: env.walletConnectProjectId,
  chains: [appChain],
  transports: {
    [appChain.id]: http(env.sepoliaRpcUrl),
  },
  ssr: false,
});
