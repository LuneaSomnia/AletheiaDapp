export const idlFactory = ({ IDL }) => {
  const ClaimId = IDL.Text;
  const AletheianId = IDL.Principal;
  const Verdict = IDL.Variant({
    'True' : IDL.Null,
    'MostlyFalse' : IDL.Null,
    'MisleadingContext' : IDL.Null,
    'Satire' : IDL.Null,
    'Opinion' : IDL.Null,
    'Unsubstantiated' : IDL.Null,
    'False' : IDL.Null,
    'Outdated' : IDL.Null,
    'MostlyTrue' : IDL.Null,
    'HalfTruth' : IDL.Null,
  });
  const Verification = IDL.Record({
    'aletheianId' : AletheianId,
    'explanation' : IDL.Text,
    'submittedAt' : IDL.Int,
    'verdict' : Verdict,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  return IDL.Service({
    'createEscalation' : IDL.Func(
        [
          ClaimId,
          IDL.Vec(AletheianId),
          IDL.Vec(Verification),
          IDL.Vec(AletheianId),
        ],
        [Result],
        [],
      ),
    'finalizeEscalation' : IDL.Func([ClaimId, Verdict], [Result], []),
    'submitSeniorVerification' : IDL.Func(
        [ClaimId, Verdict, IDL.Text],
        [Result],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
