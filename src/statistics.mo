import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

shared ({ caller = owner }) actor class RakeoffStatistics() = thisCanister {

  /////////////
  // Types ////
  /////////////

  public type RakeoffStats = {
    total_icp_stakers : Nat;
    total_icp_staked : Nat64;
  };

  //////////////////////
  // Canister State ////
  //////////////////////

  private stable var _totalStakedIcp : Nat64 = 0;

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
  public shared ({ caller }) func track_user_staked_amount(totalStakedIcp : Nat64) : async Result.Result<(), ()> {
    assert (Principal.isAnonymous(caller) == false);
    return trackUserStakedAmount(caller, totalStakedIcp);
  };

  public query func get_rakeoff_stats() : async RakeoffStats {
    return getRakeoffStats();
  };

  //////////////////////////////////
  // Private Statistic Functions ///
  //////////////////////////////////

  private func trackUserStakedAmount(userId : Principal, totalStakedIcp : Nat64) : Result.Result<(), ()> {
    _userStakedIcp.put(userId, totalStakedIcp);

    var newStakedIcpSum : Nat64 = 0;

    for (value in _userStakedIcp.vals()) {
      newStakedIcpSum += value;
    };

    _totalStakedIcp := newStakedIcpSum;

    return #ok();
  };

  private func getRakeoffStats() : RakeoffStats {
    return {
      total_icp_stakers = _userStakedIcp.size();
      total_icp_staked = _totalStakedIcp;
    };
  };
};
