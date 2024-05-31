use starknet::ContractAddress;

#[starknet::interface]
pub trait IOwnableTrait<T> {
    fn set_data(ref self: T, new_value : felt252);
    fn get_data(self: @T) -> felt252;
    fn owner(self: @T) -> ContractAddress;
    fn transfer_ownership(ref self: T, new_owner : ContractAddress);
}

#[starknet::contract]
mod OwnableContract{
    use super::{ContractAddress, IOwnableTrait};
    use starknet::get_caller_address;
    #[storage]
    struct Storage {
       owner : ContractAddress,
       data : felt252,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnershipTransfer : OwnershipTransfer,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransfer {
        #[key]
        prev_owner : ContractAddress,
        #[key]
        new_owner : ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_owner : ContractAddress){
        self.owner.write(initial_owner);
        self.data.write(1);
    }

    #[abi(embed_v0)]
    impl OwnableTraitImpl of IOwnableTrait<ContractState>{
        fn set_data(ref self: ContractState, new_value : felt252){
            self.only_owner();
            self.data.write(new_value);
        }
        fn get_data(self: @ContractState) -> felt252 {
            self.data.read()
        }
        fn owner (self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
        fn transfer_ownership(ref self: ContractState, new_owner : ContractAddress){
            self.only_owner();
            let previous_owner = self.owner.read();
            self.owner.write(new_owner);
            self.emit(OwnershipTransfer{prev_owner: previous_owner ,new_owner : new_owner});
        }
    }


    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait{
        fn only_owner (self: @ContractState){
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
        }
    }
}

