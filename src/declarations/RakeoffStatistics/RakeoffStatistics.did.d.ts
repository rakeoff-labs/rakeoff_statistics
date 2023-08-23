import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface RakeoffStatistics {
  'get_rakeoff_stats' : ActorMethod<[], RakeoffStats>,
  'set_api_key' : ActorMethod<[string], Result_1>,
  'track_user_staked_amount' : ActorMethod<[string, bigint], Result>,
}
export interface RakeoffStats {
  'total_icp_stakers' : bigint,
  'total_icp_staked' : bigint,
}
export type Result = { 'ok' : null } |
  { 'err' : null };
export type Result_1 = { 'ok' : string } |
  { 'err' : null };
export interface _SERVICE extends RakeoffStatistics {}
