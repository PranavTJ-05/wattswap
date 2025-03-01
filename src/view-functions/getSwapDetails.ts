import { surfClient } from "@/utils/surfClient";
import { WATTSWAP_ABI } from "@/utils/wattswap_abi";

export type GetSwapDetailsArguments = {
  accountAddress: string;
  swapId: number;
};

export const getSwapDetails = async (args: GetSwapDetailsArguments): Promise<any> => {
  const { accountAddress, swapId } = args;
  const result = await surfClient()
    .useABI(WATTSWAP_ABI)
    .view.get_swap_details({
      functionArguments: [accountAddress as `0x${string}`, swapId],
      typeArguments: [],
    });
  return result;
};
