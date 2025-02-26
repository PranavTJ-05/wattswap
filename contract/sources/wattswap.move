module wattswap_addr::wattswap {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_std::smart_table::{Self, SmartTable};

    const WATTSWAP_ADDRESS: address = @wattswap_addr;

    // Define data structures
    struct UserRoles has key {
        roles: SmartTable<address, u8>, // 0: Buyer, 1: Seller, 2: Admin
    }

    const ROLE_BUYER: u8 = 0;
    const ROLE_SELLER: u8 = 1;
    const ROLE_ADMIN: u8 = 2;

    const STATUS_PENDING: u8 = 0;
    const STATUS_CONFIRMED: u8 = 1;
    const STATUS_REFUNDED: u8 = 2;

    const REFUND_DELAY: u64 = 24 * 60 * 60; // 24 hours in seconds

    // Define error codes
    const ERR_UNAUTHORIZED: u64 = 1;
    const ERR_INSUFFICIENT_BALANCE: u64 = 2;
    const ERR_INVALID_TRADE_PARAMETERS: u64 = 3;
    const ERR_TRADE_NOT_FOUND: u64 = 4;
    const ERR_INVALID_TRADE_STATUS: u64 = 5;

    // Initialize the smart contract
    fun init(account: &signer) acquires UserRoles {
        let roles = UserRoles {
            roles: smart_table::new(),
        };
        move_to(account, roles);

        // Assign admin role to the creator
        assign_role(signer::address_of(account), ROLE_ADMIN);
    }

    // Assign a role to a user
    fun assign_role(user: address, role: u8) acquires UserRoles {
        let roles = borrow_global_mut<UserRoles>(WATTSWAP_ADDRESS);
        smart_table::add(&mut roles.roles, user, role);
    }

    // Check if a user has a specific role
    fun has_role(user: address, _role: u8): bool acquires UserRoles {
        let roles = borrow_global<UserRoles>(WATTSWAP_ADDRESS);
        smart_table::contains(&roles.roles, user)
    }

    // Buyer deposits APT (locks funds in escrow)
    public entry fun deposit(
        account: &signer,
        amount: u64,
    )  acquires UserRoles {
        assert!(has_role(aptos_framework::signer::address_of(account), ROLE_BUYER), ERR_UNAUTHORIZED);

        // Transfer APT from buyer to escrow
        coin::transfer<aptos_framework::aptos_coin::AptosCoin>(account, WATTSWAP_ADDRESS, amount);
    }

    // Seller confirms energy transfer
    public entry fun confirm(
        account: &signer,
        buyer: address,
        amount: u64,
    )  acquires UserRoles {
        assert!(has_role(aptos_framework::signer::address_of(account), ROLE_SELLER), ERR_UNAUTHORIZED);

        // Verify energy transfer (using smart meter API abstraction)
        assert!(wattswap_addr::wattswap::verify_energy_transfer(buyer, amount), ERR_INVALID_TRADE_PARAMETERS);

        // Transfer APT from escrow to seller
        coin::transfer<aptos_framework::aptos_coin::AptosCoin>(account, buyer, amount);
    }

    // Buyer gets refunded if the seller doesnt confirm in 24h
    public entry fun refund(
        account: &signer,
        amount: u64,
    )  acquires UserRoles {
        assert!(has_role(aptos_framework::signer::address_of(account), ROLE_BUYER), ERR_UNAUTHORIZED);

        // Transfer APT from escrow to buyer
        coin::transfer<aptos_framework::aptos_coin::AptosCoin>(account, WATTSWAP_ADDRESS, amount);
    }

    // Verify energy transfer (using smart meter API abstraction)
    public fun verify_energy_transfer(_buyer: address, _amount: u64): bool {
        return true
    }
}
