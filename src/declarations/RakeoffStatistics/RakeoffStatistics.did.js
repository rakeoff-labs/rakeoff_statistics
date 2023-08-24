export const idlFactory = ({ IDL }) => {
  const RakeoffStats = IDL.Record({
    'total_icp_rewarded' : IDL.Nat64,
    'total_icp_stakers' : IDL.Nat,
    'total_icp_staked' : IDL.Nat64,
  });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Null });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Null });
  const RakeoffStatistics = IDL.Service({
    'get_rakeoff_stats' : IDL.Func([], [RakeoffStats], []),
    'set_api_key' : IDL.Func([IDL.Text], [Result_1], []),
    'track_user_staked_amount' : IDL.Func([IDL.Text, IDL.Nat64], [Result], []),
  });
  return RakeoffStatistics;
};
export const init = ({ IDL }) => { return []; };
