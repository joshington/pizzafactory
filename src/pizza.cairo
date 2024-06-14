use starknet::ContractAddress;

#[starknet::interface]
pub trait IPizzaFactory<TContractState> {
    fn increase_pepperoni(ref self:TContractState, amount:u32);
    fn increase_pineapple(ref self:TContractState, amount:u32);
    fn get_owner(self:@TContractState) -> ContractAddress;
    fn change_owner(ref self: TContractState, new_owner:ContractAddress);
    fn make_pizza(ref self:TContractState);
    fn count_pizza(self:@TContractState) -> u32;
}

#[starknet::contract]
pub mod PizzaFactory {
    use super::IPizzaFactory;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    pub struct Storage {
        pepperoni: u32,
        pineapple: u32,
        owner: ContractAddress,
        pizzas: u32
    }
    #[constructor]
    fn constructor(ref self: ContractState, owner:ContractAddress) {
        self.pepperoni.write(10);
        self.pineapple.write(10);
        self.owner.write(owner);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        PizzaEmission: PizzaEmission
    }
    #[derive(Drop, starknet::Event)]
    pub struct PizzaEmission {
        pub counter:u32
    }

    #[abi(embed_v0)]
    impl PizzaFactoryimpl of super::IPizzaFactory<ContractState> {
        fn increase_pepperoni(ref self:ContractState, amount:u32) {
            assert!(amoutn != 0, "Amount cannot be 0");
            self.pepperoni.write(self.pepperoni.read() + amount);
        }

        fn increase_pineapple(ref self:ContractState, amount:u32) {
            assert!(amount != 0, "AMount cannot be 0");
            self.pineapple.write(self.pineapple.read() + amount);
        }

        fn make_pizza(ref self:ContractState) {
            assert!(self.pepperoni.read() > 0, "Not enough pepperoni");
            assert!(self.pineapple.read() > 0, "Not enough pineapple");

            let caller:ContractAddress = get_caller_address();
            let owner:ContractAddress = self.get_owner();

            assert!(caller == owner, "Only the owner can make pizza");

            self.pepperoni.write(self.pepperoni.read() - 1);
            self.pineapple.write(self.pineapple.read() - 1);
            self.pizzas.write(self.pizza.read() + 1);

            self.emit(PizzaEmission {counter: self.pizzas.read() });
        }

        fn get_owner(self:@ContractState) -> ContractAddress {
            self.owner.read()
        }
        fn change_owner(ref self:ContractState, new_owner:ContractAddress){
            self.set_owner(new_owner);
        }
        fn count_pizza(self: @ContractState) -> u32 {
            self.pizzas.read()
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait{
        fn set_owner(ref self:ontractState, new_owner:ContractAddress) {
            let caller:ContractAddress = get_caller_address();
            assert!(caller == self.get_owner(), "Only the owner can set ownership");

            self.owner.write(new_owner);
        }
    }
}


fn deploy_pizza_factory() -> (IPizzaFactoryDispatcher, ContractAddress) {
    let contract = declare("PizzaFactory").unwrap();
    let owner: ContractAddress = contract_address_const::<'owner'>();

    let mut constructor_calldata = array![owner.into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    let dispatcher = IPizzaFactoryDispatcher { contract_address};

    (dispatcher, contract_address)
}
//testing flow of a contract
//1.declare the class of the contract to test, identified by its name
//2.Serialize the constructor calldata into an array
//3.Deploy the contract and retrieve its address
//4.Interact with the contract's entrypoint to test various scenarios

//upon deployment contract owner should be set to the address provided in the constructor
//and the factory should have 10 units of pepperoni and pineapple and no pizzas
// If someone tries to make a pizza and they are not the owner, the operation should fail.
//  Otherwise, the pizza count should be incremented, and an event should be emitted.
// If someone tries to take ownership of the contract and they are not the owner, the 
// operation should fail. Otherwise, the owner should be updated.

#[test]
fn test_constructor() {
    let (pizza_factory, pizza_factory_address) = deploy_pizza_factory();

    let pepperoni_count = load(pizza_factory_address, selector!("pepperoni"), 1);
    let pineapple_count = load(pizza_factory_address, selector!("pineapple"), 1);
    assert_eq!(pepperoni_count, array![10]);
    assert_eq!(pineapple_count, array![10]);
    assert_eq!(pizza_factory.get_owner(), owner());
}