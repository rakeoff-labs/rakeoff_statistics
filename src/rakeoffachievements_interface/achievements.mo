module {
  public type AchievementLevel = {
    level_id : Nat;
    icp_amount_needed : Nat64;
    icp_reward : Nat64;
  };
  public type CanisterAccount = { icp_address : Text; icp_balance : Nat64 };
  public type CanisterStats = {
    ongoing_transfers : [(Principal, Nat64)];
    icp_claimed : Nat64;
    total_neurons_added : Nat;
  };
  public type NeuronAchievementDetails = {
    neuron_passes_checks : Bool;
    current_level : AchievementLevel;
    cached_level : ?AchievementLevel;
    neuron_checks : NeuronCheckResults;
    reward_amount_due : Nat64;
    neuron_id : Nat64;
  };
  public type NeuronCheckArgs = {
    dissolve_delay_seconds : Nat64;
    state : Int32;
    stake_e8s : Nat64;
    neuronId : Nat64;
    age_seconds : Nat64;
  };
  public type NeuronCheckResults = {
    is_staking : Bool;
    is_locked_for_6_months : Bool;
    two_weeks_old : Bool;
    new_achievement_reward_due : Bool;
  };
  public type Result = { #ok : CanisterStats; #err : Text };
  public type Result_1 = { #ok : CanisterAccount; #err : Text };
  public type Result_2 = { #ok : Text; #err : Text };
  public type Result_3 = { #ok : NeuronAchievementDetails; #err : Text };
  public type Self = actor {
    check_achievement_level_reward : shared query NeuronCheckArgs -> async Result_3;
    claim_achievement_level_reward : shared Nat64 -> async Result_2;
    get_canister_account : shared () -> async Result_1;
    get_canister_stats : shared query () -> async Result;
    show_available_levels : shared query () -> async [AchievementLevel];
  }
}