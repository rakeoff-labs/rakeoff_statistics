module {
  public type BlockIndex = Nat64;
  public type CanisterAccounts = {
    ckbtc_address : Text;
    icp_address : Text;
    ckbtc_balance : Nat;
    icp_balance : Nat64;
  };
  public type CanisterHttpResponsePayload = {
    status : Nat;
    body : Blob;
    headers : [HttpHeader];
  };
  public type CanisterStats = {
    icp_earned_from_swap : Nat64;
    lotto_winners : [(Principal, Nat64)];
    icp_fees_collected : Nat64;
    price_per_ticket : Nat64;
    tickets_in_lotto : Nat;
    max_tickets_allowed : Nat;
    last_winner : (Principal, Nat64);
    total_ckbtc_exchanged : Nat;
    icp_in_lotto : Nat64;
  };
  public type HttpHeader = { value : Text; name : Text };
  public type Result = { #ok : TransferResult; #err : Text };
  public type Result_1 = { #ok : RetrieveBtcOk; #err : RetrieveBtcError };
  public type Result_2 = { #ok : Result__1; #err : Text };
  public type Result_3 = { #ok : Text; #err : Text };
  public type Result_4 = { #ok : WalletInfo; #err : Text };
  public type Result_5 = { #ok : CanisterAccounts; #err : Text };
  public type Result__1 = { #Ok : Nat; #Err : TransferError__1 };
  public type RetrieveBtcError = {
    #MalformedAddress : Text;
    #GenericError : { error_message : Text; error_code : Nat64 };
    #TemporarilyUnavailable : Text;
    #AlreadyProcessing;
    #AmountTooLow : Nat64;
    #InsufficientFunds : { balance : Nat64 };
  };
  public type RetrieveBtcOk = { block_index : Nat64 };
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
  public type TransformArgs = {
    context : Blob;
    response : CanisterHttpResponsePayload;
  };
  public type WalletInfo = {
    principal : Text;
    tickets : Nat;
    btc_withdrawal_fee : Nat64;
    ckbtc_address : Text;
    icp_address : Text;
    ckbtc_balance : Nat;
    icp_balance : Nat64;
    btc_address : Text;
  };
  public type Self = actor {
    canister_withdraw_ckbtc : shared (Nat, Text) -> async Result_2;
    canister_withdraw_icp : shared (Nat64, Text) -> async Result;
    generate_winner_and_disburse_reward : shared () -> async Result_3;
    get_canister_accounts : shared () -> async Result_5;
    get_canister_stats : shared query () -> async CanisterStats;
    get_wallet_info : shared () -> async Result_4;
    participate_in_lotto : shared Nat64 -> async Result_3;
    swap_icp_to_ckbtc : shared Nat64 -> async Result_3;
    transform : shared query TransformArgs -> async CanisterHttpResponsePayload;
    withdraw_ckbtc : shared (Nat, Text) -> async Result_2;
    withdraw_ckbtc_to_btc : shared (Nat, Text) -> async Result_1;
    withdraw_icp : shared (Nat64, Text) -> async Result;
  }
}