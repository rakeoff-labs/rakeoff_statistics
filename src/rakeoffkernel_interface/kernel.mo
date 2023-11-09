module {
  public type BlockIndex = Nat64;
  public type CanisterAccounts = {
    ckbtc_address : Text;
    icp_address : Text;
    ckbtc_balance : Nat;
    icp_balance : Nat64;
  };
  public type CanisterStats = {
    icp_fees_collected : Nat64;
    icp_earned_from_disbursement : Nat64;
  };
  public type DepositRecord = {
    timestamp_nanos : Nat64;
    userId : Text;
    amount : Nat64;
  };
  public type PoolHistoryRecord = {
    timestamp_nanos : Nat64;
    token : Text;
    amount_deposited : Nat64;
    amount_disbursed : Nat64;
    success : Bool;
    drawId : Nat;
    winners : [ProcessWinnerResult];
  };
  public type PoolRecord = {
    timer : ?PoolTimer;
    token : Text;
    entries : [?DepositRecord];
    amount : Nat64;
  };
  public type PoolTimer = {
    expected_finish_date_nanos : Nat64;
    start_date_nanos : Nat64;
    timerId : Nat;
  };
  public type ProcessWinnerResult = { #ok : (Text, Nat64); #err : Text };
  public type RakeoffPools = {
    icp_pool : PoolRecord;
    pool_history : [?PoolHistoryRecord];
  };
  public type Result = { #ok : TransferResult; #err : Text };
  public type Result_1 = { #ok : Result__1; #err : Text };
  public type Result_2 = { #ok : Nat64; #err };
  public type Result_3 = { #ok : WalletInfo; #err : Text };
  public type Result_4 = { #ok : Text; #err : Text };
  public type Result_5 = { #ok : PoolTimer; #err : Text };
  public type Result_6 = { #ok : CanisterAccounts; #err : Text };
  public type Result__1 = { #Ok : Nat; #Err : TransferError__1 };
  public type Tokens = { e8s : Nat64 };
  public type TransferError = {
    #TxTooOld : { allowed_window_nanos : Nat64 };
    #BadFee : { expected_fee : Tokens };
    #TxDuplicate : { duplicate_of : BlockIndex };
    #TxCreatedInFuture;
    #InsufficientFunds : { balance : Tokens };
  };
  public type TransferError__1 = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };
  public type TransferResult = { #Ok : BlockIndex; #Err : TransferError };
  public type WalletInfo = {
    principal : Text;
    icp_pool_deposits : Nat64;
    ckbtc_address : Text;
    icp_address : Text;
    ckbtc_balance : Nat;
    icp_balance : Nat64;
  };
  public type Self = actor {
    controller_canister_withdraw_ckbtc : shared (Nat, Text) -> async Result_1;
    controller_canister_withdraw_icp : shared (Nat64, Text) -> async Result;
    controller_deposit_icp_pool : shared (Text, Nat64) -> async Result_4;
    controller_generate_icp_winners : shared () -> async ();
    controller_get_canister_accounts : shared () -> async Result_6;
    controller_init_pool_timer : shared Text -> async Result_5;
    deposit_icp_pool : shared Nat64 -> async Result_4;
    get_canister_stats : shared query () -> async CanisterStats;
    get_rakeoff_pools : shared query () -> async RakeoffPools;
    get_wallet_info : shared () -> async Result_3;
    update_disbursed_icp_fee : shared Nat64 -> async Result_2;
    withdraw_ckbtc : shared (Nat, Text) -> async Result_1;
    withdraw_icp : shared (Nat64, Text) -> async Result;
  }
}