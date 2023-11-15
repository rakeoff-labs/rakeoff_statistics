import RakeoffKernelInterface "./rakeoffkernel_interface/kernel";
import RakeoffAchievementsInterface "./rakeoffachievements_interface/achievements";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Timer "mo:base/Timer";
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

  // The amount of time it takes for the api to refresh
  let API_REFRESH_TIME_NANOS : Nat = (24 * 60 * 60 * 1_000_000_000); // 24 hours

  /////////////
  // Types ////
  /////////////

  public type HistoryChartData = {
    timestamp : Nat64;
    amount : Nat64;
  };

  public type Stats = {
    total_stakers : Nat; // from stats
    total_staked : Nat64; // from stats
    claimed_from_achievements : Nat64; // from achievements
    total_neurons_in_achievements : Nat; // from achievements
    total_rewarded : Nat64; // from kernel
    average_win_amount : Nat64; // from kernel
    highest_win_amount : Nat64; // from kernel
    average_per_pool : Nat64; // from kernel
    highest_pool : Nat64; // from kernel
    total_pools_successfully_completed : Nat; // from kernel
    total_winners_processed : Nat; // from kernel
    total_winner_processing_failures : Nat; // from kernel
    pool_history_chart_data : [HistoryChartData]; // from kernel
    fees_collected : Nat64; // from kernel
    fees_from_disbursement : Nat64; // from kernel
  };

  public type RakeoffStats = {
    icp_stats : Stats;
  };

  //////////////////////
  // Canister State ////
  //////////////////////

  // stable variable of all Rakeoff stats - cached
  private stable var _rakeoffStats : ?RakeoffStats = null;

  // api key (secret)
  private stable var _apiKey : Text = "";

  // Hashmap of user Id and their total staked ICP amount
  private var _userStakedIcp = HashMap.HashMap<Principal, Nat64>(10, Principal.equal, Principal.hash);

  // Maintain stable hashmap state
  private stable var _userStakedIcpStorage : [(Principal, Nat64)] = [];

  // Maintain the current timer id
  private stable var _refreshTimerId : Nat = 0;

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
    // Reset the timer after upgrades
    ignore setRefreshTimer();
    // Prune the server cache
    ignore server.cache.pruneAll();
  };

  ////////////////////////
  // Public Functions ////
  ////////////////////////

  public shared ({ caller }) func track_user_staked_amount(key : Text, totalStakedIcp : Nat64) : async Result.Result<(), ()> {
    assert (Principal.isAnonymous(caller) == false);
    return trackUserStakedAmount(key, caller, totalStakedIcp);
  };

  public query func get_rakeoff_stats() : async ?RakeoffStats {
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

  public shared ({ caller }) func controller_set_refresh_timer() : async Result.Result<Text, ()> {
    assert (caller == owner);
    return setRefreshTimer();
  };

  public shared ({ caller }) func controller_get_refresh_timer() : async Result.Result<Nat, ()> {
    assert (caller == owner);
    return getRefreshTimerId();
  };

  public shared ({ caller }) func controller_update_cached_stats() : async () {
    assert (caller == owner);
    return await updateCachedStats();
  };

  //////////////////////////////////
  // Private Statistic Functions ///
  //////////////////////////////////

  private func trackUserStakedAmount(key : Text, userId : Principal, totalStakedIcp : Nat64) : Result.Result<(), ()> {
    if (key == _apiKey) {
      _userStakedIcp.put(userId, totalStakedIcp);

      return #ok();
    } else {
      return #err();
    };
  };

  private func getRakeoffStats() : ?RakeoffStats {
    switch (_rakeoffStats) {
      case (?_rakeoffStats) {
        return ?_rakeoffStats;
      };
      case (null) {
        return null;
      };
    };
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

  private func setRefreshTimer() : Result.Result<Text, ()> {
    // Safety cancel
    Timer.cancelTimer(_refreshTimerId);

    // Set the timer
    let id = Timer.recurringTimer(
      #nanoseconds(API_REFRESH_TIME_NANOS),
      updateCachedStats,
    );

    _refreshTimerId := id;

    return #ok("Reccuring timer set with ID: " # Nat.toText(_refreshTimerId));
  };

  private func getRefreshTimerId() : Result.Result<Nat, ()> {
    return #ok(_refreshTimerId);
  };

  private func updateCachedStats() : async () {
    server.empty_cache();

    switch (
      await RakeoffAchievements.get_canister_stats(),
      await RakeoffKernel.get_rakeoff_pools(),
      await RakeoffKernel.get_canister_stats(),
    ) {
      case (#ok achievementStats, kernelPools, kernelStats) {
        _rakeoffStats := ?{
          icp_stats = {
            total_stakers = tallyTotalStakers();
            total_staked = tallyTotalStakedAmount();
            claimed_from_achievements = getIcpClaimedFromAchievements(achievementStats);
            total_neurons_in_achievements = getTotalNeuronsInAchievements(achievementStats);
            total_rewarded = tallyTotalIcpRewarded(kernelPools);
            fees_collected = totalIcpFeesCollected(kernelStats);
            fees_from_disbursement = totalIcpFeesFromIcpDisbursement(kernelStats);
            average_win_amount = calculateAverageIcpWinAmount(kernelPools);
            highest_win_amount = getHighestIcpWinAmount(kernelPools);
            average_per_pool = calculateAverageIcpPerPool(kernelPools);
            highest_pool = getHighestIcpPoolAmount(kernelPools);
            total_pools_successfully_completed = tallyTotalSuccessfulPool(kernelPools);
            total_winners_processed = tallyTotalWinnersProcessed(kernelPools);
            total_winner_processing_failures = tallyTotalWinnersProcessingFailures(kernelPools);
            pool_history_chart_data = getPoolHistoryChartData(kernelPools);
          };
          total_icp_stakers = tallyTotalStakers();
          total_icp_staked = tallyTotalStakedAmount();
          total_icp_rewarded = tallyTotalIcpRewarded(kernelPools);
        };

      };
      case _ {}; // do nothing
    };
  };

  ///////////////////////////////
  // Private Helper Functions ///
  ///////////////////////////////

  // Purpose: Calculate the total number of ICP stakers on Rakeoff.
  // Returns: Total number of stakers as a Nat.
  private func tallyTotalStakers() : Nat {
    return _userStakedIcp.size();
  };

  // Purpose: Compute the total amount of staked ICP based on the data in the stats canister.
  // Returns: Total staked ICP amount as a Nat64.
  private func tallyTotalStakedAmount() : Nat64 {
    var newStakedIcpSum : Nat64 = 0;

    for (value in _userStakedIcp.vals()) {
      newStakedIcpSum += value;
    };

    return newStakedIcpSum;
  };

  // Purpose: Retrieve the total ICP claimed from the ICP bonus achievements canister.
  // Parameters: achievementStats - RakeoffAchievementsInterface.CanisterStats object.
  // Returns: Total ICP claimed as a Nat64.
  private func getIcpClaimedFromAchievements(achievementStats : RakeoffAchievementsInterface.CanisterStats) : Nat64 {
    return achievementStats.icp_claimed;
  };

  // Purpose: Get the total count of neurons (batches of staked ICP) from the ICP bonus achievements canister.
  // Parameters: achievementStats - RakeoffAchievementsInterface.CanisterStats object.
  // Returns: Total neuron count as a Nat.
  private func getTotalNeuronsInAchievements(achievementStats : RakeoffAchievementsInterface.CanisterStats) : Nat {
    return achievementStats.total_neurons_added;
  };

  // Purpose: Calculate the total ICP fees collected, based on the kernel stats.
  // Parameters: kernelStats - RakeoffKernelInterface.CanisterStats object.
  // Returns: Total ICP fees collected as a Nat64.
  private func totalIcpFeesCollected(kernelStats : RakeoffKernelInterface.CanisterStats) : Nat64 {
    return kernelStats.icp_fees_collected;
  };

  // Purpose: Compute the total ICP fees earned from ICP disbursement.
  // Parameters: kernelStats - RakeoffKernelInterface.CanisterStats object.
  // Returns: Total ICP fees from disbursement as a Nat64.
  private func totalIcpFeesFromIcpDisbursement(kernelStats : RakeoffKernelInterface.CanisterStats) : Nat64 {
    return kernelStats.icp_earned_from_disbursement;
  };

  // Purpose: Determine the total amount of ICP disbursed to winners from the RakeoffKernel.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: Total ICP rewarded as a Nat64.
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

  // Purpose: Count the total number of winners processed successfully.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: Total number of processed winners as a Nat.
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

  // Purpose: Count the total number of processing failures for winners' transfers.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: Total number of processing failures as a Nat.
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

  // Purpose: Calculate the total number of ICP pools from RakeoffKernel with all transfers successful.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: Total number of successful ICP pools as a Nat.
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

  // Purpose: Compute the average ICP win amount from the pools.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: Average ICP win amount as a Nat64.
  private func calculateAverageIcpWinAmount(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat64 {
    let totalRewarded = tallyTotalIcpRewarded(kernelPools);
    let winnersCount = tallyTotalWinnersProcessed(kernelPools);

    // Check for division by zero
    if (winnersCount == 0) {
      return 0;
    } else {
      return totalRewarded / Nat64.fromNat(winnersCount);
    };
  };

  // Purpose: Calculate the average ICP amount per pool.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: Average ICP per pool as a Nat64.
  private func calculateAverageIcpPerPool(kernelPools : RakeoffKernelInterface.RakeoffPools) : Nat64 {
    let totalRewarded = tallyTotalIcpRewarded(kernelPools);
    let poolCount = kernelPools.pool_history.size();

    // Check for division by zero
    if (poolCount == 0) {
      return 0;
    } else {
      return totalRewarded / Nat64.fromNat(poolCount);
    };
  };

  // Purpose: Identify the highest amount of ICP that was deposited in a single pool.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: Highest ICP pool amount as a Nat64.
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

  // Purpose: Determine the highest winning amount of ICP from the pools.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: Highest ICP win amount as a Nat64.
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

  // Purpose: Create a chart data array showing pool history with timestamp and amount.
  // Parameters: kernelPools - RakeoffKernelInterface.RakeoffPools object.
  // Returns: An array of HistoryChartData containing timestamp and amount for each pool record.
  private func getPoolHistoryChartData(kernelPools : RakeoffKernelInterface.RakeoffPools) : [HistoryChartData] {
    let historyChartData = Array.mapFilter(
      kernelPools.pool_history,
      func(x : ?RakeoffKernelInterface.PoolHistoryRecord) : ?HistoryChartData {
        switch (x) {
          case (?historyRecord) {
            ?{
              timestamp = historyRecord.timestamp_nanos;
              amount = historyRecord.amount_disbursed;
            };
          };
          case (null) { null };
        };
      },
    );

    return historyChartData;
  };

  // Purpose: Convert pool history data into JSON format.
  // Parameters: poolChartHistory - Array of HistoryChartData with pool history data.
  // Returns: JSON formatted string of the pool history.
  private func poolHistoryToJson(poolChartHistory : [HistoryChartData]) : Text {
    var poolHistoryJson = "[";
    var i = 0;
    let totalSize : Nat = poolChartHistory.size() - 1;

    for (historyEntry in poolChartHistory.vals()) {
      poolHistoryJson := poolHistoryJson # "{ \"timestamp\": " # Nat64.toText(historyEntry.timestamp) # "," # "\"amount\": " # Nat64.toText(historyEntry.amount) # "}";
      if (i < totalSize) {
        poolHistoryJson := poolHistoryJson # ",";
      };
      i += 1;
    };

    poolHistoryJson := poolHistoryJson # "]";

    return poolHistoryJson;
  };

  ///////////////////////////
  // Server JSON Response ///
  ///////////////////////////

  server.get(
    "/" # API_VERSION # "/rakeoff-stats",
    func(req, res) : Server.Response {
      switch (_rakeoffStats) {
        case (?_rakeoffStats) {
          var json = "{ \"icp_stats\": {" #
          "\"total_stakers\": " # Nat.toText(_rakeoffStats.icp_stats.total_stakers) # ", " #
          "\"total_staked\": " # Nat64.toText(_rakeoffStats.icp_stats.total_staked) # ", " #
          "\"claimed_from_achievements\": " # Nat64.toText(_rakeoffStats.icp_stats.claimed_from_achievements) # ", " #
          "\"total_neurons_in_achievements\": " # Nat.toText(_rakeoffStats.icp_stats.total_neurons_in_achievements) # ", " #
          "\"total_rewarded\": " # Nat64.toText(_rakeoffStats.icp_stats.total_rewarded) # ", " #
          "\"average_win_amount\": " # Nat64.toText(_rakeoffStats.icp_stats.average_win_amount) # ", " #
          "\"highest_win_amount\": " # Nat64.toText(_rakeoffStats.icp_stats.highest_win_amount) # ", " #
          "\"average_per_pool\": " # Nat64.toText(_rakeoffStats.icp_stats.average_per_pool) # ", " #
          "\"highest_pool\": " # Nat64.toText(_rakeoffStats.icp_stats.highest_pool) # ", " #
          "\"total_pools_successfully_completed\": " # Nat.toText(_rakeoffStats.icp_stats.total_pools_successfully_completed) # ", " #
          "\"total_winners_processed\": " # Nat.toText(_rakeoffStats.icp_stats.total_winners_processed) # ", " #
          "\"total_winner_processing_failures\": " # Nat.toText(_rakeoffStats.icp_stats.total_winner_processing_failures) # ", " #
          "\"pool_history_chart_data\": " # poolHistoryToJson(_rakeoffStats.icp_stats.pool_history_chart_data) # ", " #
          "\"fees_collected\": " # Nat64.toText(_rakeoffStats.icp_stats.fees_collected) # ", " #
          "\"fees_from_disbursement\": " # Nat64.toText(_rakeoffStats.icp_stats.fees_from_disbursement) #
          " }}";

          return res.json({
            status_code = 200;
            body = json;
            cache_strategy = #noCache;
          });
        };
        case (null) {
          return res.send({
            status_code = 404;
            headers = [];
            body = Text.encodeUtf8("API data not found");
            streaming_strategy = null;
            cache_strategy = #noCache;
          });
        };
      };
    },
  );
};
