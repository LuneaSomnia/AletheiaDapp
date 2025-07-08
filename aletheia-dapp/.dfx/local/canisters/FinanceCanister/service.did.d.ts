import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type AletheianId = Principal;
export type ICP = bigint;
export type Result = { 'ok' : string } |
  { 'err' : string };
export interface _SERVICE {
  'addToPool' : ActorMethod<[ICP], undefined>,
  'distributePaymentPool' : ActorMethod<[], undefined>,
  'recordXp' : ActorMethod<[AletheianId, bigint], undefined>,
  'withdraw' : ActorMethod<[ICP], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
