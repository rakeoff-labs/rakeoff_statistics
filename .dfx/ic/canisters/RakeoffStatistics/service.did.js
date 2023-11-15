export const idlFactory = ({ IDL }) => {
  const Result_1 = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Null });
  const Result_2 = IDL.Variant({ 'ok' : IDL.Nat, 'err' : IDL.Null });
  const HistoryChartData = IDL.Record({
    'timestamp' : IDL.Nat64,
    'amount' : IDL.Nat64,
  });
  const Stats = IDL.Record({
    'total_winners_processed' : IDL.Nat,
    'total_rewarded' : IDL.Nat64,
    'total_neurons_in_achievements' : IDL.Nat,
    'total_winner_processing_failures' : IDL.Nat,
    'highest_pool' : IDL.Nat64,
    'fees_from_disbursement' : IDL.Nat64,
    'total_staked' : IDL.Nat64,
    'highest_win_amount' : IDL.Nat64,
    'pool_history_chart_data' : IDL.Vec(HistoryChartData),
    'average_win_amount' : IDL.Nat64,
    'total_stakers' : IDL.Nat,
    'fees_collected' : IDL.Nat64,
    'claimed_from_achievements' : IDL.Nat64,
    'average_per_pool' : IDL.Nat64,
    'total_pools_successfully_completed' : IDL.Nat,
  });
  const RakeoffStats = IDL.Record({ 'icp_stats' : Stats });
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
    'controller_get_refresh_timer' : IDL.Func([], [Result_2], []),
    'controller_set_api_key' : IDL.Func([IDL.Text], [Result_1], []),
    'controller_set_refresh_timer' : IDL.Func([], [Result_1], []),
    'controller_update_cached_stats' : IDL.Func([], [], []),
    'get_rakeoff_stats' : IDL.Func([], [IDL.Opt(RakeoffStats)], ['query']),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'http_request_update' : IDL.Func([HttpRequest], [HttpResponse], []),
    'track_user_staked_amount' : IDL.Func([IDL.Text, IDL.Nat64], [Result], []),
  });
  return RakeoffStatistics;
};
export const init = ({ IDL }) => { return []; };
