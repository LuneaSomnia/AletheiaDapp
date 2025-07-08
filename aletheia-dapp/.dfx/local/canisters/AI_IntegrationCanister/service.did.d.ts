import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type Claim = string;
export type ClaimId = string;
export interface Question { 'question' : string, 'explanation' : string }
export interface ResearchResult {
  'url' : string,
  'source' : string,
  'credibilityScore' : number,
  'summary' : string,
}
export interface SynthesisInput { 'explanation' : string, 'verdict' : string }
export interface SynthesisResult {
  'explanation' : string,
  'verdict' : string,
  'evidenceHighlights' : Array<string>,
}
export interface _SERVICE {
  'generateQuestions' : ActorMethod<[ClaimId, Claim], Array<Question>>,
  'getQuestions' : ActorMethod<[ClaimId], [] | [Array<Question>]>,
  'getResearch' : ActorMethod<[ClaimId], [] | [Array<ResearchResult>]>,
  'retrieveInformation' : ActorMethod<[ClaimId, Claim], Array<ResearchResult>>,
  'synthesizeReport' : ActorMethod<
    [ClaimId, Array<SynthesisInput>, Array<ResearchResult>],
    SynthesisResult
  >,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
