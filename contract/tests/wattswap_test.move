#[test_only]
module wattswap_addr::wattswap_test {
    use std::string;
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_std::smart_table;
    use aptos_framework::signer;

    use wattswap_addr::wattswap;

    #[test_only]
    const ADMIN_ADDRESS: address = @0xcafe;
    #[test_only]
    const BUYER_ADDRESS: address = @0xbeef;
    #[test_only]
    const SELLER_ADDRESS: address = @0xface;

    #[test(sender = @0xcafe)]
    fun test_init(sender: &signer) {
        wattswap::init(sender);

        // Verify that the UserRoles resource is created
        assert!(exists<wattswap::UserRoles>(@wattswap_addr), 0);

        // Verify that the admin role is assigned to the creator
        assert!(wattswap::has_role(signer::address_of(sender), 2), 1);
    }

    #[test(sender = @0xcafe)]
    fun test_assign_role(sender: &signer) acquires wattswap::UserRoles {
        wattswap::init(sender);

        // Assign buyer role to buyer address
        wattswap::assign_role(BUYER_ADDRESS, 0);
        assert!(wattswap::has_role(BUYER_ADDRESS, 0), 0);

        // Assign seller role to seller address
        wattswap::assign_role(SELLER_ADDRESS, 1);
        assert!(wattswap::has_role(SELLER_ADDRESS, 1), 1);
    }

    #[test(sender = @0xcafe)]
    fun test_deposit(sender: &signer) acquires wattswap::UserRoles {
        // Create accounts
        account::create_account(ADMIN_ADDRESS);
        account::create_account(BUYER_ADDRESS);
        account::create_account(SELLER_ADDRESS);

        // Initialize the contract
        wattswap::init(sender);

        // Assign buyer role
        wattswap::assign_role(BUYER_ADDRESS, 0);

        // Register coin for buyer
        coin::register<aptos_framework::aptos_coin::AptosCoin>(sender);

        // Mint coins for buyer
        coin::mint<aptos_framework::aptos_coin::AptosCoin>(sender, BUYER_ADDRESS, 1000);

        let initial_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(BUYER_ADDRESS);

        // Deposit coins
        let deposit_amount: u64 = 500;
        wattswap::deposit(&(account::create_signer(BUYER_ADDRESS)), deposit_amount);

        let final_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(BUYER_ADDRESS);

        // Verify that the buyer's balance has decreased
        assert!(final_balance == initial_balance - deposit_amount, 0);

        // Verify that the contract's balance has increased
        let contract_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(@wattswap_addr);
        assert!(contract_balance == deposit_amount, 1);
    }

    // #[test(sender = @0xcafe)]
    // fun test_confirm(sender: &signer) acquires wattswap::UserRoles {
    //     // Create accounts
    //     account::create_account(ADMIN_ADDRESS);
    //     account::create_account(BUYER_ADDRESS);
    //     account::create_account(SELLER_ADDRESS);

    //     // Initialize the contract
    //     wattswap::init(sender);

    //     // Assign roles
    //     wattswap::assign_role(BUYER_ADDRESS, 0);
    //     wattswap::assign_role(SELLER_ADDRESS, 1);

    //     // Register coin for buyer and seller
    //     coin::register<aptos_framework::aptos_coin::AptosCoin>(sender);

    //     // Mint coins for buyer
    //     coin::mint<aptos_framework::aptos_coin::AptosCoin>(sender, BUYER_ADDRESS, 1000);

    //     // Deposit coins
    //     let deposit_amount: u64 = 500;
    //     wattswap::deposit(&(account::create_signer(BUYER_ADDRESS)), deposit_amount);

    //     let initial_buyer_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(BUYER_ADDRESS);
    //     let initial_seller_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(SELLER_ADDRESS);

    //     // Confirm energy transfer
    //     wattswap::confirm(&(account::create_signer(SELLER_ADDRESS)), BUYER_ADDRESS, deposit_amount);

    //     let final_buyer_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(BUYER_ADDRESS);
    //     let final_seller_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(SELLER_ADDRESS);

    //     // Verify that the buyer's balance has decreased
    //     assert!(final_buyer_balance == initial_buyer_balance - deposit_amount, 0);

    //     // Verify that the seller's balance has increased
    //     assert!(final_seller_balance == initial_seller_balance + deposit_amount, 1);
    // }

    // #[test(sender = @0xcafe)]
    // fun test_refund(sender: &signer) acquires wattswap::UserRoles {
    //     // Create accounts
    //     account::create_account(ADMIN_ADDRESS);
    //     account::create_account(BUYER_ADDRESS);
    //     account::create_account(SELLER_ADDRESS);

    //     // Initialize the contract
    //     wattswap::init(sender);

    //     // Assign buyer role
    //     wattswap::assign_role(BUYER_ADDRESS, 0);

    //     // Register coin for buyer
    //     coin::register<aptos_framework::aptos_coin::AptosCoin>(sender);

    //     // Mint coins for buyer
    //     coin::mint<aptos_framework::aptos_coin::AptosCoin>(sender, BUYER_ADDRESS, 1000);

    //     // Deposit coins
    //     let deposit_amount: u64 = 500;
    //     wattswap::deposit(&(account::create_signer(BUYER_ADDRESS)), deposit_amount);

    //     let initial_buyer_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(BUYER_ADDRESS);

    //     // Refund
    //     wattswap::refund(&(account::create_signer(BUYER_ADDRESS)), deposit_amount);

    //     let final_buyer_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(BUYER_ADDRESS);

    //     // Verify that the buyer's balance has increased
    //     assert!(final_buyer_balance == initial_buyer_balance + deposit_amount, 0);

    //     // Verify that the contract's balance has decreased
    //     let contract_balance = coin::balance<aptos_framework::aptos_coin::AptosCoin>(@wattswap_addr);
    //     assert!(contract_balance == 0, 1);
    // }
}
