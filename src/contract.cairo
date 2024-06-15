use starknet::ContractAddress;
//above represents a starknet contract Address

#[starknet::interface]
trait OwnableTrait<T>{
    fn transfer_ownership(ref self:T, new_owner:ContractAddress);
    fn get_owner(self:@T) -> ContractAddress;
}
//above specifies funcs for transferring and getting ownership


#[starknet::contract]
mod Ownable {
    use super::ContractAddress;
    use starknet::get_caller_address;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnershipTransferred: OwnershipTransferred,
    }
    //===indicates ownership change with previous and new owner details
    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        #[key]
        prev_owner:ContractAddress,
        #[key]
        new_owner:ContractAddress,
    }

    #[storage]
    struct Storage {
        owner:ContractAddress,
    }
    //holds the contract's state with the current owner's address.
    #[constructor]
    fn constructor(ref self:ContractAddress, init_owner:ContractAddress){
        self.owner.write(init_owner);
        //this initializes the contract with a starting owner.
    }

    #[abi(embed_v0)]
    impl OwnableImpl of super::OwnableTrait<ContractState> {
        fn transfer_ownership(ref self:ContractState, new_owner:ContractAddress) {
            self.only_owner();
            let prev_owner = self.owner.read();
            self.owner.write(new_owner);
            self.emit(Event::OwnershipTransferred(OwnershipTransferred {
                prev_owner: prev_owner,
                new_owner: new_owner,
            }));
        }
        fn get_owner(self:@ContractState) -> ContractAddress {
            self.owner.read()
        }
    }
    //funcs for transferring ownership and retrieving the current owner's details

    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait {
        fn only_owner(self:@ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
        }
    }
    //only-owner => validates if the caller is the current owner.
}