import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type ClaimId = string;
export interface Evidence {
  'contentHash' : string,
  'credibilityScore' : bigint,
  'sourceUrl' : string,
}
export interface FactRecord {
  'aletheians' : Array<Principal>,
  'claim' : string,
  'explanation' : string,
  'previousVersion' : [] | [FactRecord],
  'verdict' : Verdict,
  'version' : bigint,
  'evidence' : Array<Evidence>,
  'verifiedAt' : bigint,
}
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Verdict = { 'True' : null } |
  { 'MostlyFalse' : null } |
  { 'MisleadingContext' : null } |
  { 'Satire' : null } |
  { 'Opinion' : null } |
  { 'Unsubstantiated' : null } |
  { 'False' : null } |
  { 'Outdated' : null } |
  { 'MostlyTrue' : null } |
  { 'HalfTruth' : null };
export interface _SERVICE {
  'getClaimHistory' : ActorMethod<[ClaimId], Array<FactRecord>>,
  'getFact' : ActorMethod<[ClaimId], [] | [FactRecord]>,
  'searchClaims' : ActorMethod<[string], Array<FactRecord>>,
  'storeFact' : ActorMethod<
    [ClaimId, string, Verdict, string, Array<Evidence>, Array<Principal>],
    Result
  >,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
