export const idlFactory = ({ IDL }) => {
  const RakeoffStats = IDL.Record({
    'total_icp_stakers' : IDL.Nat,
    'total_icp_staked' : IDL.Nat64,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Null });
  const RakeoffStatistics = IDL.Service({
    'get_rakeoff_stats' : IDL.Func([], [RakeoffStats], ['query']),
    'track_user_staked_amount' : IDL.Func([IDL.Nat64], [Result], []),
  });
  return RakeoffStatistics;
};
export const init = ({ IDL }) => { return []; };
