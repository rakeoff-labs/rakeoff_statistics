import RakeoffKernelInterface "./rakeoffkernel_interface/kernel";
import RakeoffAchievementsInterface "./rakeoffachievements_interface/achievements";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Server "mo:server";

// Welcome to the RakeoffStatistics smart contract.
// This smart contract is built to track some important stats about the Rakeoff dApp

shared ({ caller = owner }) actor class RakeoffStatistics() = thisCanister {

  /////////////////
  // Constants ////
  /////////////////

  // RakeoffKernel canister
  let RakeoffKernel = actor "rktkb-jiaaa-aaaap-aa23a-cai" : RakeoffKernelInterface.Self;

  // RakeoffKernel canister
  let RakeoffAchievements = actor "4llet-lqaaa-aaaai-qpbkq-cai" : RakeoffAchievementsInterface.Self;

  // API version
  let API_VERSION : Text = "v1";

  /////////////
  // Types ////
  /////////////

  public type Timestamp = Text;
  public type PoolAmount = Text;

  public type RakeoffStats = {
    total_icp_stakers : Nat; // from stats
    total_icp_staked : Nat64; // from stats
    icp_claimed_from_achievements : Nat64; // from achievements
    total_neurons_in_achievements : Nat; // from achievements
    total_icp_rewarded : Nat64; // from kernel
    average_icp_win_amount : Nat64; // from kernel
    highest_icp_win_amount : Nat64;
    average_icp_per_pool : Nat64;
    highest_icp_pool : Nat64;
    total_icp_pools_successfully_completed : Nat;
    total_icp_winners_processed : Nat;
    total_icp_winner_processing_failures : Nat;
    pool_history_chart_data : [(Timestamp, PoolAmount)]; // returns as strings for the server
    icp_fees_collected : Nat64; // from kernel
    icp_fees_from_icp_disbursement : Nat64; // from kernel
  };

  //////////////////////
  // Canister State ////
  //////////////////////

  // stable variable of all Rakeoff stats - cached
  private stable var _rakeoffStats : RakeoffStats = {
    total_icp_stakers = 0;
    total_icp_staked = 0;
    icp_claimed_from_achievements = 0;
    total_neurons_in_achievements = 0;
    total_icp_rewarded = 0;
    icp_fees_collected = 0;
    icp_fees_from_icp_disbursement = 0;
    average_icp_win_amount = 0;
    highest_icp_win_amount = 0;
    average_icp_per_pool = 0;
    highest_icp_pool = 0;
    total_icp_pools_successfully_completed = 0;
    total_icp_winners_processed = 0;
    total_icp_winner_processing_failures = 0;
    pool_history_chart_data = [("0", "0")];
  };

  // api key (secret)
  private stable var _apiKey : Text = "";

  // Hashmap of user Id and their total staked ICP amount
  private var _userStakedIcp = HashMap.HashMap<Principal, Nat64>(10, Principal.equal, Principal.hash);

  // Maintain stable hashmap state
  private stable var _userStakedIcpStorage : [(Principal, Nat64)] = [];

  // Maintain the server cache
  stable var serializedEntries : Server.SerializedEntries = ([], [], [owner]);
  var server = Server.Server({ serializedEntries });

  system func preupgrade() {
    _userStakedIcpStorage := Iter.toArray(_userStakedIcp.entries());
    serializedEntries := server.entries();
  };

  system func postupgrade() {
    _userStakedIcp := HashMap.fromIter(
      Iter.fromArray(_userStakedIcpStorage),
      _userStakedIcpStorage.size(),
      Principal.equal,
      Principal.hash,
    );
    ignore server.cache.pruneAll();
  };

  ////////////////////////
  // Public Functions ////
  ////////////////////////

  public shared ({ caller }) func track_user_staked_amount(key : Text, totalStakedIcp : Nat64) : async Result.Result<(), ()> {
    assert (Principal.isAnonymous(caller) == false);
    return trackUserStakedAmount(key, caller, totalStakedIcp);
  };

  public query func get_rakeoff_stats() : async RakeoffStats {
    return getRakeoffStats();
  };

  public query func http_request(req : Server.HttpRequest) : async Server.HttpResponse {
    server.http_request(req);
  };

  public func http_request_update(req : Server.HttpRequest) : async Server.HttpResponse {
    server.http_request_update(req);
  };

  public shared ({ caller }) func controller_clear_server_cache() : async () {
    assert (caller == owner);
    server.empty_cache();
  };

  public shared ({ caller }) func controller_set_api_key(key : Text) : async Result.Result<Text, ()> {
    assert (caller == owner);
    return setApiKey(key);
  };

  public shared ({ caller }) func controller_get_api_key() : async Result.Result<Text, ()> {
    assert (caller == owner);
    return getApiKey();
  };

  public shared ({ caller }) func controller_update_cached_stats() : async () {
    assert (caller == owner);
    return await updateCachedStats();
  };

  //////////////////////////////////
  // Private Statistic Functions ///
  //////////////////////////////////

  server.get(
    "/" # API_VERSION # "/rakeoff-stats",
    func(req, res) : Server.Response {

      var json = "{ " #
      "\"total_icp_stakers\": " # Nat.toText(_rakeoffStats.total_icp_stakers) # ", " #
      "\"total_icp_staked\": " # Nat64.toText(_rakeoffStats.total_icp_staked) # ", " #
      "\"icp_claimed_from_achievements\": " # Nat64.toText(_rakeoffStats.icp_claimed_from_achievements) # ", " #
      "\"total_neurons_in_achievements\": " # Nat.toText(_rakeoffStats.total_neurons_in_achievements) # ", " #
      "\"total_icp_rewarded\": " # Nat64.toText(_rakeoffStats.total_icp_rewarded) # ", " #
      "\"average_icp_win_amount\": " # Nat64.toText(_rakeoffStats.average_icp_win_amount) # ", " #
      "\"highest_icp_win_amount\": " # Nat64.toText(_rakeoffStats.highest_icp_win_amount) # ", " #
      "\"average_icp_per_pool\": " # Nat64.toText(_rakeoffStats.average_icp_per_pool) # ", " #
      "\"highest_icp_pool\": " # Nat64.toText(_rakeoffStats.highest_icp_pool) # ", " #
      "\"total_icp_pools_successfully_completed\": " # Nat.toText(_rakeoffStats.total_icp_pools_successfully_completed) # ", " #
      "\"total_icp_winners_processed\": " # Nat.toText(_rakeoffStats.total_icp_winners_processed) # ", " #
      "\"total_icp_winner_processing_failures\": " # Nat.toText(_rakeoffStats.total_icp_winner_processing_failures) # ", " #
      "\"pool_history_chart_data\": " # "[]" # ", " # // TODO - add chart data
      "\"icp_fees_collected\": " # Nat64.toText(_rakeoffStats.icp_fees_collected) # ", " #
      "\"icp_fees_from_icp_disbursement\": " # Nat64.toText(_rakeoffStats.icp_fees_from_icp_disbursement) #
      " }";

      res.json({
        status_code = 200;
        body = json;
        cache_strategy = #noCache;
      });
    },
  );

  private func trackUserStakedAmount(key : Text, userId : Principal, totalStakedIcp : Nat64) : Result.Result<(), ()> {
    if (key == _apiKey) {
      _userStakedIcp.put(userId, totalStakedIcp);

      return #ok();
    } else {
      return #err();
    };
  };

  private func getRakeoffStats() : RakeoffStats {
    return _rakeoffStats;
  };

  //////////////////////////////
  // Private Admin Functions ///
  //////////////////////////////

  private func setApiKey(key : Text) : Result.Result<Text, ()> {
    _apiKey := key;
    return #ok(_apiKey);
  };

  private func getApiKey() : Result.Result<Text, ()> {
    return #ok(_apiKey);
  };

  private func updateCachedStats() : async () {
    server.empty_cache();

    switch (
      await RakeoffAchievements.get_canister_stats(),
      await RakeoffKernel.get_rakeoff_pools(),
      await RakeoffKernel.get_canister_stats(),
    ) {
      case (#ok achievementStats, kernelPools, kernelStats) {
        _rakeoffStats := {
          total_icp_stakers = tallyTotalStakers();
          total_icp_staked = tallyTotalStakedAmount();
          icp_claimed_from_achievements = getIcpClaimedFromAchievements(achievementStats);
          total_neurons_in_achievements = getTotalNeuronsInAchievements(achievementStats);
          total_icp_rewarded = tallyTotalIcpRewarded(kernelPools);
          icp_fees_collected = totalIcpFeesCollected(kernelStats);
          icp_fees_from_icp_disbursement = totalIcpFeesFromIcpDisbursement(kernelStats);
          average_icp_win_amount = calculateAverageIcpWinAmount(kernelPools);
          highest_icp_win_amount = getHighestIcpWinAmount(kernelPools);
          average_icp_per_pool = calculateAverageIcpPerPool(kernelPools);
          highest_icp_pool = getHighestIcpPoolAmount(kernelPools);
          total_icp_pools_successfully_completed = tallyTotalSuccessfulPool(kernelPools);
          total_icp_winners_processed = tallyTotalWinnersProcessed(kernelPools);
          total_icp_winner_processing_failures = tallyTotalWinnersProcessingFailures(kernelPools);
          pool_history_chart_data = getPoolHistoryChartData(kernelPools);
        };
      };
      case _ {
        // do nothing
      };
    };
  };

  ///////////////////////////////////////////
  // Private Calculation Helper Functions ///
  ///////////////////////////////////////////

  // gets the total amount of stakers on Rakeoff
  private func tallyTotalStakers() : Nat {
    return _userStakedIcp.size();
  };

  // gets the total amount of staked ICP based on the info stored here in the stats canister
  private func tallyTotalStakedAmount() : Nat64 {
    var newStakedIcpSum : Nat64 = 0;

    for (value in _userStakedIcp.vals()) {
      newStakedIcpSum += value;
    };

    return newStakedIcpSum;
  };

  // get the total icp claimed from the ICP bonus achievements canister
  private func getIcpClaimedFromAchievements(achievementStats : RakeoffAchievementsInterface.CanisterStats) : Nat64 {
    return achievementStats.icp_claimed;
  };

  // get the total neurons (batches of staked ICP) from the ICP bonus achievements canister
  private func getTotalNeuronsInAchievements(achievementStats : RakeoffAchievementsInterface.CanisterStats) : Nat {
    return achievementStats.total_neurons_added;
  };

  private func totalIcpFeesCollected(kernelStats : RakeoffKernelInterface.CanisterStats) : Nat64 {
    return kernelStats.icp_fees_collected;
  };

  private func totalIcpFeesFromIcpDisbursement(kernelStats : RakeoffKernelInterface.CanisterStats) : Nat64 {
    return kernelStats.icp_earned_from_disbursement;
  };

  // gets the total amount of icp disbursed to winners from the RakeoffKernel
  private func tallyTotalIcpRewarded(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat64 {
    let oldPrizes : Nat64 = 8600000000; // as of our last update the old prizes were erased
    var totalPrizes : Nat64 = 0;

    for (pool in kernelPools.pool_history.vals()) {
      switch (pool) {
        case (?pool) {
          totalPrizes += pool.amount_disbursed;
        };
        case _ {};
      };
    };

    return totalPrizes + oldPrizes;
  };

  // gets the total amount of #ok transfers disbursed to winners from the RakeoffKernel
  private func tallyTotalWinnersProcessed(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat {
    var totalWinners = 0;
    for (pool in kernelPools.pool_history.vals()) {
      switch (pool) {
        case (?pool) {
          for (winner in pool.winners.vals()) {
            switch (winner) {
              case (#ok result) {
                totalWinners += 1;
              };
              case _ {};
            };
          };
        };
        case _ {};
      };
    };

    return totalWinners;
  };

  // gets the total amount of #err transfers disbursed to winners from the RakeoffKernel
  private func tallyTotalWinnersProcessingFailures(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat {
    var totalFailures = 0;
    for (pool in kernelPools.pool_history.vals()) {
      switch (pool) {
        case (?pool) {
          for (winner in pool.winners.vals()) {
            switch (winner) {
              case (#ok result) {};
              case _ {
                totalFailures += 1;
              };
            };
          };
        };
        case _ {};
      };
    };

    return totalFailures;
  };

  // gets the total amount of ICP pools from RakeoffKernel with all transfers successful
  private func tallyTotalSuccessfulPool(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat {
    var totalSuccesses = 0;
    for (pool in kernelPools.pool_history.vals()) {
      switch (pool) {
        case (?pool) {
          if (pool.success) {
            totalSuccesses += 1;
          };
        };
        case _ {};
      };
    };

    return totalSuccesses;
  };

  // calculate the average icp win amount from the pools
  private func calculateAverageIcpWinAmount(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat64 {
    return tallyTotalIcpRewarded(kernelPools) / Nat64.fromNat(tallyTotalWinnersProcessed(kernelPools));
  };

  // calculate the average icp per pool
  private func calculateAverageIcpPerPool(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat64 {
    return tallyTotalIcpRewarded(kernelPools) / Nat64.fromNat(kernelPools.pool_history.size());
  };

  // get the highest amount of ICP that was deposited in a single pool
  private func getHighestIcpPoolAmount(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat64 {
    var highestAmount : Nat64 = 0;
    for (pool in kernelPools.pool_history.vals()) {
      switch (pool) {
        case (?pool) {
          if (pool.amount_deposited > highestAmount) {
            highestAmount := pool.amount_deposited;
          };
        };
        case _ {};
      };
    };

    return highestAmount;
  };

  // get the highest winning amount of ICP
  private func getHighestIcpWinAmount(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat64 {
    var highestAmount : Nat64 = 0;
    for (pool in kernelPools.pool_history.vals()) {
      switch (pool) {
        case (?pool) {
          for (winner in pool.winners.vals()) {
            switch (winner) {
              case (#ok result) {
                if (result.1 > highestAmount) {
                  highestAmount := result.1;
                };
              };
              case _ {};
            };
          };
        };
        case _ {};
      };
    };

    return highestAmount;
  };

  // TODO
  private func getPoolHistoryChartData(kernelPools : RakeoffKernelInterface.RakeoffPools) : [(Timestamp, PoolAmount)] {
    return [("0", "0")];
  };

};
