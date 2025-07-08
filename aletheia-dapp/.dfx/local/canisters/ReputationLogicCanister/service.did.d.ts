import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type Action = { 'TrainingComplete' : null } |
  { 'CouncilResolution' : null } |
  { 'AccuracyBonus' : null } |
  { 'DuplicateIdentification' : null } |
  { 'SuccessfulVerification' : null } |
  { 'EscalationReview' : null } |
  { 'Mentoring' : null } |
  { 'SpeedBonus' : null } |
  { 'ComplexityBonus' : bigint } |
  { 'Penalty' : bigint };
export type AletheianId = Principal;
export interface PerformanceMetrics {
  'claimsVerified' : bigint,
  'avgVerificationTime' : bigint,
  'escalationsResolved' : bigint,
  'accuracy' : number,
}
export type Rank = { 'Junior' : null } |
  { 'Trainee' : null } |
  { 'Associate' : null } |
  { 'Senior' : null } |
  { 'Master' : null } |
  { 'Expert' : null };
export type Result = { 'ok' : bigint } |
  { 'err' : string };
export interface _SERVICE {
  'getPerformance' : ActorMethod<[AletheianId], [] | [PerformanceMetrics]>,
  'getRank' : ActorMethod<[AletheianId], [] | [Rank]>,
  'getWarnings' : ActorMethod<[AletheianId], [] | [bigint]>,
  'getXP' : ActorMethod<[AletheianId], [] | [bigint]>,
  'initializeAletheian' : ActorMethod<[AletheianId], undefined>,
  'updatePerformance' : ActorMethod<
    [
      AletheianId,
      { 'EscalationsResolved' : bigint } |
        { 'VerificationTime' : bigint } |
        { 'ClaimsVerified' : bigint } |
        { 'Accuracy' : number },
    ],
    undefined
  >,
  'updateXP' : ActorMethod<[AletheianId, Action], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
