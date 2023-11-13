import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface CallbackStrategy {
  'token' : Token,
  'callback' : [Principal, string],
}
export type HeaderField = [string, string];
export interface HttpRequest {
  'url' : string,
  'method' : string,
  'body' : Uint8Array | number[],
  'headers' : Array<HeaderField>,
}
export interface HttpResponse {
  'body' : Uint8Array | number[],
  'headers' : Array<HeaderField>,
  'upgrade' : [] | [boolean],
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export type PoolAmount = string;
export interface RakeoffStatistics {
  'controller_clear_server_cache' : ActorMethod<[], undefined>,
  'controller_get_api_key' : ActorMethod<[], Result_1>,
  'controller_set_api_key' : ActorMethod<[string], Result_1>,
  'controller_update_cached_stats' : ActorMethod<[], undefined>,
  'get_rakeoff_stats' : ActorMethod<[], RakeoffStats>,
  'http_request' : ActorMethod<[HttpRequest], HttpResponse>,
  'http_request_update' : ActorMethod<[HttpRequest], HttpResponse>,
  'track_user_staked_amount' : ActorMethod<[string, bigint], Result>,
}
export interface RakeoffStats {
  'average_icp_per_pool' : bigint,
  'average_icp_win_amount' : bigint,
  'total_neurons_in_achievements' : bigint,
  'icp_claimed_from_achievements' : bigint,
  'highest_icp_win_amount' : bigint,
  'highest_icp_pool' : bigint,
  'total_icp_pools_successfully_completed' : bigint,
  'total_icp_winners_processed' : bigint,
  'icp_fees_collected' : bigint,
  'pool_history_chart_data' : Array<[Timestamp, PoolAmount]>,
  'total_icp_rewarded' : bigint,
  'total_icp_stakers' : bigint,
  'icp_fees_from_icp_disbursement' : bigint,
  'total_icp_winner_processing_failures' : bigint,
  'total_icp_staked' : bigint,
}
export type Result = { 'ok' : null } |
  { 'err' : null };
export type Result_1 = { 'ok' : string } |
  { 'err' : null };
export interface StreamingCallbackHttpResponse {
  'token' : [] | [Token],
  'body' : Uint8Array | number[],
}
export type StreamingStrategy = { 'Callback' : CallbackStrategy };
export type Timestamp = string;
export interface Token { 'arbitrary_data' : string }
export interface _SERVICE extends RakeoffStatistics {}