import { surfClient } from "@/utils/surfClient";
import { WATTSWAP_ABI } from "@/utils/wattswap_abi";

export type GetSwapsArguments = {
  accountAddress: string;
};

export const getSwaps = async (args: GetSwapsArguments): Promise<any> => {
  const { accountAddress } = args;
  const result = await surfClient()
    .useABI(WATTSWAP_ABI)
    .view.get_swaps({
      functionArguments: [accountAddress as `0x${string}`],
      typeArguments: [],
    });
  return result;
};
