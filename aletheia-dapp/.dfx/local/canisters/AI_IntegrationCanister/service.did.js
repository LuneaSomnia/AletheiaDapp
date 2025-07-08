export const idlFactory = ({ IDL }) => {
  const ClaimId = IDL.Text;
  const Claim = IDL.Text;
  const Question = IDL.Record({
    'question' : IDL.Text,
    'explanation' : IDL.Text,
  });
  const ResearchResult = IDL.Record({
    'url' : IDL.Text,
    'source' : IDL.Text,
    'credibilityScore' : IDL.Float64,
    'summary' : IDL.Text,
  });
  const SynthesisInput = IDL.Record({
    'explanation' : IDL.Text,
    'verdict' : IDL.Text,
  });
  const SynthesisResult = IDL.Record({
    'explanation' : IDL.Text,
    'verdict' : IDL.Text,
    'evidenceHighlights' : IDL.Vec(IDL.Text),
  });
  return IDL.Service({
    'generateQuestions' : IDL.Func([ClaimId, Claim], [IDL.Vec(Question)], []),
    'getQuestions' : IDL.Func(
        [ClaimId],
        [IDL.Opt(IDL.Vec(Question))],
        ['query'],
      ),
    'getResearch' : IDL.Func(
        [ClaimId],
        [IDL.Opt(IDL.Vec(ResearchResult))],
        ['query'],
      ),
    'retrieveInformation' : IDL.Func(
        [ClaimId, Claim],
        [IDL.Vec(ResearchResult)],
        [],
      ),
    'synthesizeReport' : IDL.Func(
        [ClaimId, IDL.Vec(SynthesisInput), IDL.Vec(ResearchResult)],
        [SynthesisResult],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
