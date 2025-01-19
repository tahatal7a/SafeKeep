use starknet::ContractAddress;

#[starknet::interface]
trait IGuardianRegistry<TContractState> {
    fn register_child(
        ref self: TContractState,
        child_id: felt252,
        guardian: ContractAddress
    );
    fn add_guardian(
        ref self: TContractState, 
        child_id: felt252, 
        guardian_address: ContractAddress
    );

    fn is_guardian(
        self: @TContractState,
        child_id: felt252,
        guardian_address: ContractAddress
    ) -> bool;

    fn raise_emergency_alert(
        ref self: TContractState, 
        child_id: felt252, 
        alert_message: felt252
    );
}

#[derive(Drop, Serde, starknet::Store)]
struct ChildRecord {
    id: felt252,
    primary_guardian: ContractAddress,
    registration_time: u64
}

#[starknet::contract]
mod YourContract {
    use starknet::ContractAddress;
    use super::ChildRecord;
    use starknet::storage::StorageMapWriteAccess;

    #[storage]
    struct Storage {
        children: starknet::storage::Map<felt252, ChildRecord>,
        guardians: starknet::storage::Map<(felt252, ContractAddress), bool>,
        emergency_alerts: starknet::storage::Map<felt252, felt252>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ChildRegistered: ChildRegistered,
        GuardianAdded: GuardianAdded,
        GuardianRemoved: GuardianRemoved,
        EmergencyAlertRaised: EmergencyAlertRaised
    }

    #[derive(Drop, starknet::Event)]
    struct ChildRegistered {
        #[key]
        child_id: felt252,
        primary_guardian: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct GuardianAdded {
        #[key]
        child_id: felt252,
        #[key]
        guardian: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct GuardianRemoved {
        #[key]
        child_id: felt252,
        #[key]
        guardian: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct EmergencyAlertRaised {
        #[key]
        child_id: felt252,
        alert_message: felt252,
        reporter: ContractAddress
    }

    #[abi(embed_v0)]
    impl GuardianRegistryImpl of super::IGuardianRegistry<ContractState> {
        fn register_child(
            ref self: ContractState,
            child_id: felt252,
            guardian: ContractAddress
        ) {
            let child_record = ChildRecord {
                id: child_id,
                primary_guardian: guardian,
                registration_time: starknet::get_block_timestamp()
            };

            self.children.write(child_id, child_record);

            self.guardians.write((child_id, guardian), true);
            self.emit(
                ChildRegistered {
                    child_id,
                    primary_guardian: guardian,
                    timestamp: starknet::get_block_timestamp()
                }
            );
        }

        fn add_guardian(
            ref self: ContractState,
            child_id: felt252,
            guardian_address: ContractAddress
        ) {
            self.guardians.write((child_id, guardian_address), true);

            self.emit(
                GuardianAdded {
                    child_id,
                    guardian: guardian_address
                }
            );
        }

            fn is_guardian(
                self: @ContractState,
                child_id: felt252,
                guardian_address: ContractAddress
            ) -> bool {
                self.guardians.read((child_id, guardian_address))
            }
    
            fn raise_emergency_alert(
                ref self: ContractState,
                child_id: felt252,
                alert_message: felt252
            ) {
                self.emergency_alerts.write(child_id, alert_message);
    
                self.emit(
                    EmergencyAlertRaised {
                        child_id,
                        alert_message,
                        reporter: starknet::get_caller_address()
                    }
                );
                    }
                }
        }