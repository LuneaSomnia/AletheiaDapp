import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type Badge = string;
export interface PerformanceMetrics {
  'claimsVerified' : bigint,
  'avgVerificationTime' : bigint,
  'escalationsResolved' : bigint,
  'accuracy' : number,
}
export interface Profile {
  'xp' : bigint,
  'username' : [] | [string],
  'createdAt' : bigint,
  'badges' : Array<Badge>,
  'rank' : Rank,
  'warnings' : bigint,
  'performance' : PerformanceMetrics,
  'lastActive' : bigint,
}
export type Rank = { 'Junior' : null } |
  { 'Trainee' : null } |
  { 'Associate' : null } |
  { 'Senior' : null } |
  { 'Master' : null } |
  { 'Expert' : null };
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Result_1 = { 'ok' : Profile } |
  { 'err' : string };
export interface _SERVICE {
  'addBadge' : ActorMethod<[Badge], Result>,
  'createProfile' : ActorMethod<[[] | [string]], Result>,
  'getProfile' : ActorMethod<[], Result_1>,
  'updateProfile' : ActorMethod<[[] | [string]], Result>,
  'updateXP' : ActorMethod<[bigint], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
