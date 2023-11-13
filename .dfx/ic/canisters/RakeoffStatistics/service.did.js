export const idlFactory = ({ IDL }) => {
  const Result_1 = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Null });
  const Timestamp = IDL.Text;
  const PoolAmount = IDL.Text;
  const RakeoffStats = IDL.Record({
    'average_icp_per_pool' : IDL.Nat64,
    'average_icp_win_amount' : IDL.Nat64,
    'total_neurons_in_achievements' : IDL.Nat,
    'icp_claimed_from_achievements' : IDL.Nat64,
    'highest_icp_win_amount' : IDL.Nat64,
    'highest_icp_pool' : IDL.Nat64,
    'total_icp_pools_successfully_completed' : IDL.Nat,
    'total_icp_winners_processed' : IDL.Nat,
    'icp_fees_collected' : IDL.Nat64,
    'pool_history_chart_data' : IDL.Vec(IDL.Tuple(Timestamp, PoolAmount)),
    'total_icp_rewarded' : IDL.Nat64,
    'total_icp_stakers' : IDL.Nat,
    'icp_fees_from_icp_disbursement' : IDL.Nat64,
    'total_icp_winner_processing_failures' : IDL.Nat,
    'total_icp_staked' : IDL.Nat64,
  });
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const Token = IDL.Record({ 'arbitrary_data' : IDL.Text });
  const StreamingCallbackHttpResponse = IDL.Record({
    'token' : IDL.Opt(Token),
    'body' : IDL.Vec(IDL.Nat8),
  });
  const CallbackStrategy = IDL.Record({
    'token' : Token,
    'callback' : IDL.Func([Token], [StreamingCallbackHttpResponse], ['query']),
  });
  const StreamingStrategy = IDL.Variant({ 'Callback' : CallbackStrategy });
  const HttpResponse = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
    'upgrade' : IDL.Opt(IDL.Bool),
    'streaming_strategy' : IDL.Opt(StreamingStrategy),
    'status_code' : IDL.Nat16,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Null });
  const RakeoffStatistics = IDL.Service({
    'controller_clear_server_cache' : IDL.Func([], [], []),
    'controller_get_api_key' : IDL.Func([], [Result_1], []),
    'controller_set_api_key' : IDL.Func([IDL.Text], [Result_1], []),
    'controller_update_cached_stats' : IDL.Func([], [], []),
    'get_rakeoff_stats' : IDL.Func([], [RakeoffStats], ['query']),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'http_request_update' : IDL.Func([HttpRequest], [HttpResponse], []),
    'track_user_staked_amount' : IDL.Func([IDL.Text, IDL.Nat64], [Result], []),
  });
  return RakeoffStatistics;
};
export const init = ({ IDL }) => { return []; };
