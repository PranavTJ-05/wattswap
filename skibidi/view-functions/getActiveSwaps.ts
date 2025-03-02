import { surfClient } from "@/utils/surfClient";
import { WATTSWAP_ABI } from "@/utils/wattswap_abi";

export type GetActiveSwapsArguments = {
  accountAddress: string;
};

export const getActiveSwaps = async (args: GetActiveSwapsArguments): Promise<any> => {
  const { accountAddress } = args;
  const result = await surfClient()
    .useABI(WATTSWAP_ABI)
    .view.get_active_swaps({
      functionArguments: [accountAddress as `0x${string}`],
      typeArguments: [],
    });
  return result;
};
