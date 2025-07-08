import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface Claim {
  'id' : ClaimId,
  'status' : { 'Processing' : null } |
    { 'Completed' : null } |
    { 'Pending' : null },
  'content' : string,
  'context' : [] | [string],
  'source' : [] | [string],
  'userId' : Principal,
  'submittedAt' : bigint,
  'claimType' : ClaimType,
}
export type ClaimId = string;
export type ClaimType = { 'Url' : null } |
  { 'Link' : null } |
  { 'Text' : null } |
  { 'Image' : null } |
  { 'Audio' : null } |
  { 'Video' : null };
export type Event = {
    'ClaimStatusUpdated' : {
      'id' : ClaimId,
      'oldStatus' : { 'Processing' : null } |
        { 'Completed' : null } |
        { 'Pending' : null },
      'newStatus' : { 'Processing' : null } |
        { 'Completed' : null } |
        { 'Pending' : null },
    }
  } |
  { 'ClaimSubmitted' : Claim };
export type Result = { 'ok' : ClaimId } |
  { 'err' : string };
export interface _SERVICE {
  'addEventListener' : ActorMethod<[[Principal, string]], undefined>,
  'getClaim' : ActorMethod<[ClaimId], [] | [Claim]>,
  'getUserClaims' : ActorMethod<[bigint, bigint], Array<Claim>>,
  'removeEventListener' : ActorMethod<[[Principal, string]], undefined>,
  'submitClaim' : ActorMethod<
    [string, ClaimType, [] | [string], [] | [string]],
    Result
  >,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
