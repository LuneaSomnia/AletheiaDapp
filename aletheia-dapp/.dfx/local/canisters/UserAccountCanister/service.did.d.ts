import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type ClaimId = string;
export type Result = { 'ok' : UserProfile } |
  { 'err' : string };
export type Result_1 = { 'ok' : null } |
  { 'err' : string };
export interface UserProfile {
  'username' : [] | [string],
  'submittedClaims' : Array<ClaimId>,
  'createdAt' : bigint,
  'learningPoints' : bigint,
  'lastActive' : bigint,
}
export interface _SERVICE {
  'addLearningPoints' : ActorMethod<[bigint], Result_1>,
  'addSubmittedClaim' : ActorMethod<[ClaimId], Result_1>,
  'createProfile' : ActorMethod<[[] | [string]], Result_1>,
  'getProfile' : ActorMethod<[], Result>,
}
