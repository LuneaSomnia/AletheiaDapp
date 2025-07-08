import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type AletheianId = Principal;
export type ClaimId = string;
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
export interface Verification {
  'aletheianId' : AletheianId,
  'explanation' : string,
  'submittedAt' : bigint,
  'verdict' : Verdict,
}
export interface _SERVICE {
  'createEscalation' : ActorMethod<
    [ClaimId, Array<AletheianId>, Array<Verification>, Array<AletheianId>],
    Result
  >,
  'finalizeEscalation' : ActorMethod<[ClaimId, Verdict], Result>,
  'submitSeniorVerification' : ActorMethod<[ClaimId, Verdict, string], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
