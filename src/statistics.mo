import RakeoffKernelInterface "./rakeoffkernel_interface/kernel";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

// Welcome to the RakeoffStatistics smart contract.
// This smart contract is built to track some important stats about the Rakeoff dApp

shared ({ caller = owner }) actor class RakeoffStatistics() = thisCanister {
  /////////////////
  // Constants ////
  /////////////////

  // RakeoffKernel canister
  let RakeoffKernel = actor "rktkb-jiaaa-aaaap-aa23a-cai" : RakeoffKernelInterface.Self;

  /////////////
  // Types ////
  /////////////

  public type RakeoffStats = {
    total_icp_stakers : Nat;
    total_icp_staked : Nat64;
    total_icp_rewarded : Nat64;
  };

  //////////////////////
  // Canister State ////
  //////////////////////

  private stable var _totalStakedIcp : Nat64 = 0;

  // api key
  private stable var _apiKey : Text = "";

  // Hashmap of user Id and their total staked ICP amount
  private var _userStakedIcp = HashMap.HashMap<Principal, Nat64>(10, Principal.equal, Principal.hash);

  // Maintain stable hashmap state
  private stable var _userStakedIcpStorage : [(Principal, Nat64)] = [];

  system func preupgrade() {
    _userStakedIcpStorage := Iter.toArray(_userStakedIcp.entries());
  };

  system func postupgrade() {
    _userStakedIcp := HashMap.fromIter(
      Iter.fromArray(_userStakedIcpStorage),
      _userStakedIcpStorage.size(),
      Principal.equal,
      Principal.hash,
    );
  };

  ////////////////////////
  // Public Functions ////
  ////////////////////////

  public shared ({ caller }) func set_api_key(key : Text) : async Result.Result<Text, ()> {
    assert (caller == owner);
    return setApiKey(key);
  };

  public shared ({ caller }) func track_user_staked_amount(key : Text, totalStakedIcp : Nat64) : async Result.Result<(), ()> {
    assert (Principal.isAnonymous(caller) == false);
    return trackUserStakedAmount(key, caller, totalStakedIcp);
  };

  public func get_rakeoff_stats() : async RakeoffStats {
    return await getRakeoffStats();
  };

  //////////////////////////////////
  // Private Statistic Functions ///
  //////////////////////////////////

  private func trackUserStakedAmount(key : Text, userId : Principal, totalStakedIcp : Nat64) : Result.Result<(), ()> {
    if (key == _apiKey) {
      _userStakedIcp.put(userId, totalStakedIcp);

      var newStakedIcpSum : Nat64 = 0;

      for (value in _userStakedIcp.vals()) {
        newStakedIcpSum += value;
      };

      _totalStakedIcp := newStakedIcpSum;

      return #ok();
    } else {
      return #err();
    };
  };

  private func getRakeoffStats() : async RakeoffStats {
    let kernelStats = await RakeoffKernel.get_canister_stats();

    let winners = kernelStats.lotto_winners;
    var totalAmount : Nat64 = 0;

    for ((_, amount) in winners.vals()) {
      totalAmount += amount;
    };

    return {
      total_icp_stakers = _userStakedIcp.size();
      total_icp_staked = _totalStakedIcp;
      total_icp_rewarded = totalAmount;
    };
  };

  //////////////////////////////
  // Private Admin Functions ///
  //////////////////////////////

  private func setApiKey(key : Text) : Result.Result<Text, ()> {
    _apiKey := key;
    return #ok(_apiKey);
  };

};
