import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type AletheianId = Principal;
export interface AletheianProfile {
  'id' : AletheianId,
  'status' : string,
  'reputation' : bigint,
  'expertise' : Array<string>,
  'lastActive' : bigint,
  'location' : [] | [string],
}
export interface Claim {
  'id' : ClaimId,
  'complexity' : string,
  'content' : string,
  'submittedAt' : bigint,
  'category' : [] | [string],
}
export type ClaimId = string;
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Result_1 = { 'ok' : bigint } |
  { 'err' : string };
export interface _SERVICE {
  'addClaim' : ActorMethod<[Claim], Result>,
  'assignClaims' : ActorMethod<[], Result>,
  'getWorkload' : ActorMethod<[AletheianId], Result_1>,
  'registerAletheian' : ActorMethod<[AletheianProfile], Result>,
  'updateAletheianStatus' : ActorMethod<[AletheianId, string], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
