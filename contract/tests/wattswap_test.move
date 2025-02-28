module wattswap_addr::wattswap_test {
    use std::signer;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use wattswap_addr::wattswap;

    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use aptos_framework::coin;
    #[test_only]
    use std::vector;

    #[test(account = @0x1)]
    fun test_initialize_swaps(account: signer) {
        wattswap::initialize_swaps(&account);
    }

   #[test(account = @0x1)]
    #[expected_failure(abort_code = 0, location = wattswap)]
    fun test_double_initialize(account: signer) {
        wattswap::initialize_swaps(&account);
        wattswap::initialize_swaps(&account);
    }


    #[test(seller = @0x1)]
    fun test_create_swap(seller: signer) {
        let watt_amount = 100;
        let apt_price = 50;

        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, watt_amount, apt_price);

        let swaps = wattswap::get_swaps(@0x1);
        assert!(vector::length(&swaps) == 1, 0);
        let (id, seller_addr, buyer_addr, watt_amount_check, apt_price_check, is_active) = wattswap::get_swap_details(@0x1, 1);

        assert!(id == 1, 1); //id
        assert!(seller_addr == @0x1, 2); //seller
        assert!(buyer_addr == @0x0, 3); //buyer
        assert!(watt_amount_check == watt_amount, 4); //watt_amount
        assert!(apt_price_check == apt_price, 5); //apt_price
        assert!(is_active == true, 6); //is_active

    }

    #[test(seller = @0x1)]
    fun test_create_swap_zero_values(seller: signer) {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 0, 0);

        let swaps = wattswap::get_swaps(@0x1);
        assert!(vector::length(&swaps) == 1, 0);

        let (id, seller_addr, buyer_addr, watt_amount_check, apt_price_check, is_active) = wattswap::get_swap_details(@0x1, 1);
        assert!(watt_amount_check == 0, 1);
        assert!(apt_price_check == 0, 2);
    }

    #[test(seller = @0x1)]
    fun test_create_multiple_swaps(seller: signer) {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);
        wattswap::create_swap(&seller, 200, 100);

        let swaps = wattswap::get_swaps(@0x1);
        assert!(vector::length(&swaps) == 2, 0);

        let (id1, _, _, _, _, _) = wattswap::get_swap_details(@0x1, 1);
        let (id2, _, _, _, _, _) = wattswap::get_swap_details(@0x1, 2);
        assert!(id1 == 1, 1); // Check id is 1
        assert!(id2 == 2, 2); // Check id is 2
    }

        #[test(seller = @0x1, buyer = @0x2)]
    fun test_successful_purchase(seller: signer, buyer: signer) {
        let watt_amount = 100;
        let apt_price = 50;

        // Initialize and create swap
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, watt_amount, apt_price);

        // Fund the buyer
        coin::register<AptosCoin>(&buyer);
        account::create_account_for_test(@0x2);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x2, apt_price);

        // Purchase the swap
        wattswap::purchase(&buyer, @0x1, 1);

        // Check swap details
        let (id, seller_addr, buyer_addr, watt_amount_check, apt_price_check, is_active) = wattswap::get_swap_details(@0x1, 1);

        assert!(buyer_addr == @0x2, 0);
        assert!(is_active == false, 1);

        // Check balances (would need a mock coin module for precise checks)

    }

    #[test(seller = @0x1, buyer = @0x2)]
    #[expected_failure(abort_code = wattswap::E_SWAP_NOT_FOUND, location = wattswap)]
    fun test_purchase_swap_not_found(seller: signer, buyer: signer) {
        wattswap::initialize_swaps(&seller);
        coin::register<AptosCoin>(&buyer);
        account::create_account_for_test(@0x2);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x2, 100);
        wattswap::purchase(&buyer, @0x1, 1); // Swap ID 1 doesn't exist
    }

    #[test(seller = @0x1, buyer = @0x2)]
    #[expected_failure(abort_code = wattswap::E_SWAP_NOT_ACTIVE, location = wattswap)]
    fun test_purchase_swap_not_active(seller: signer, buyer: signer) {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);

        coin::register<AptosCoin>(&buyer);
        account::create_account_for_test(@0x2);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x2, 100);

        wattswap::purchase(&buyer, @0x1, 1);
        wattswap::purchase(&buyer, @0x1, 1); // Purchase again
    }

   #[test(seller = @0x1, buyer1 = @0x2, buyer2 = @0x3)]
    #[expected_failure(abort_code = wattswap::E_SWAP_NOT_ACTIVE, location = wattswap)]
    fun test_purchase_already_purchased(seller: signer, buyer1: signer, buyer2: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);

        coin::register<AptosCoin>(&buyer1);
        coin::register<AptosCoin>(&buyer2);
        account::create_account_for_test(@0x2);
        account::create_account_for_test(@0x3);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x2, 100);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x3, 100);

        wattswap::purchase(&buyer1, @0x1, 1);
        wattswap::purchase(&buyer2, @0x1, 1); // Different buyer tries to purchase
    }

    #[test(seller = @0x1, buyer = @0x2)]
    #[expected_failure(abort_code = 0, location = aptos_framework)] // Assuming coin transfer failure aborts with 0. Need a better way to test this.
    fun test_purchase_insufficient_balance(seller: signer, buyer: signer) {

        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);

        coin::register<AptosCoin>(&buyer);
        account::create_account_for_test(@0x2);
        // Don't fund the buyer
        wattswap::purchase(&buyer, @0x1, 1);
    }

     #[test(seller = @0x1)]
    #[expected_failure(abort_code = wattswap::E_NOT_BUYER, location = wattswap)]
    fun test_purchase_own_swap(seller: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);

        coin::register<AptosCoin>(&seller);
        account::create_account_for_test(@0x1);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x1, 50);

        wattswap::purchase(&seller, @0x1, 1); // Seller tries to buy their own swap
    }

    #[test(seller = @0x1, buyer = @0x2)]
    fun test_confirm(seller: signer, buyer: signer) {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);

        coin::register<AptosCoin>(&buyer);
        account::create_account_for_test(@0x2);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x2, 50);
        wattswap::purchase(&buyer, @0x1, 1);

        wattswap::confirm(&seller, 1);
    }

     #[test(seller = @0x1, buyer = @0x2)]
    #[expected_failure(abort_code = wattswap::E_SWAP_NOT_FOUND, location = wattswap)]
    fun test_confirm_swap_not_found(seller: signer, buyer: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::confirm(&seller, 1); // Swap ID 1 doesn't exist
    }

    #[test(seller = @0x1, buyer = @0x2, other = @0x3)]
    #[expected_failure(abort_code = wattswap::E_NOT_SELLER, location = wattswap)]
    fun test_confirm_not_seller(seller: signer, buyer: signer, other: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);

        coin::register<AptosCoin>(&buyer);
        account::create_account_for_test(@0x2);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x2, 50);
        wattswap::purchase(&buyer, @0x1, 1);

        wattswap::confirm(&other, 1); // 'other' is not the seller
    }

    #[test(seller = @0x1)]
    fun test_get_swaps_no_swaps(seller: signer) {
        wattswap::initialize_swaps(&seller);
        let swaps = wattswap::get_swaps(@0x1);
        assert!(vector::length(&swaps) == 0, 0);
    }

    #[test(seller = @0x1)]
    fun test_get_swaps_one_swap(seller: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);
        let swaps = wattswap::get_swaps(@0x1);
        assert!(vector::length(&swaps) == 1, 0);
    }

    #[test(seller = @0x1)]
    fun test_get_swaps_multiple_swaps(seller: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);
        wattswap::create_swap(&seller, 200, 100);
        let swaps = wattswap::get_swaps(@0x1);
        assert!(vector::length(&swaps) == 2, 0);
    }

     #[test(seller = @0x1, buyer = @0x2)]
    fun test_get_active_swaps_no_active(seller: signer, buyer: signer) {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);

        coin::register<AptosCoin>(&buyer);
        account::create_account_for_test(@0x2);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x2, 50);
        wattswap::purchase(&buyer, @0x1, 1);

        let active_swaps = wattswap::get_active_swaps(@0x1);
        assert!(vector::length(&active_swaps) == 0, 0);
    }

    #[test(seller = @0x1)]
    fun test_get_active_swaps_one_active(seller: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);
        let active_swaps = wattswap::get_active_swaps(@0x1);
        assert!(vector::length(&active_swaps) == 1, 0);
    }

    #[test(seller = @0x1, buyer = @0x2)]
    fun test_get_active_swaps_mixed(seller: signer, buyer: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50); // Active
        wattswap::create_swap(&seller, 200, 100); // Will be inactive

        coin::register<AptosCoin>(&buyer);
        account::create_account_for_test(@0x2);
        coin::transfer<AptosCoin>(&aptos_framework::genesis_signer(), @0x2, 100);
        wattswap::purchase(&buyer, @0x1, 2);

        let active_swaps = wattswap::get_active_swaps(@0x1);
        assert!(vector::length(&active_swaps) == 1, 0);
        let (id, _, _, _, _, _) = wattswap::get_swap_details(@0x1, vector::borrow(&active_swaps, 0).id);
        assert!(id == 1, 1); //check id of active swap
    }

    #[test(seller = @0x1)]
    fun test_get_swap_details_found(seller: signer)  {
        wattswap::initialize_swaps(&seller);
        wattswap::create_swap(&seller, 100, 50);
        let (id, seller_addr, buyer_addr, watt_amount, apt_price, is_active) = wattswap::get_swap_details(@0x1, 1);

        assert!(id == 1, 0);
        assert!(seller_addr == @0x1, 1);
        assert!(buyer_addr == @0x0, 2);
        assert!(watt_amount == 100, 3);
        assert!(apt_price == 50, 4);
        assert!(is_active == true, 5);
    }


    #[test(seller = @0x1)]
    #[expected_failure(abort_code = wattswap::E_SWAP_NOT_FOUND, location = wattswap)]
    fun test_get_swap_details_not_found(seller: signer) {
        wattswap::initialize_swaps(&seller);
        wattswap::get_swap_details(@0x1, 1); // Swap ID 1 doesn't exist
    }

}
