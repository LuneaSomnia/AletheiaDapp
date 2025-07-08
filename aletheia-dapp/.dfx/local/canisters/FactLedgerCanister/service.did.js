export const idlFactory = ({ IDL }) => {
  const FactRecord = IDL.Rec();
  const ClaimId = IDL.Text;
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
  const Evidence = IDL.Record({
    'contentHash' : IDL.Text,
    'credibilityScore' : IDL.Nat,
    'sourceUrl' : IDL.Text,
  });
  FactRecord.fill(
    IDL.Record({
      'aletheians' : IDL.Vec(IDL.Principal),
      'claim' : IDL.Text,
      'explanation' : IDL.Text,
      'previousVersion' : IDL.Opt(FactRecord),
      'verdict' : Verdict,
      'version' : IDL.Nat,
      'evidence' : IDL.Vec(Evidence),
      'verifiedAt' : IDL.Int,
    })
  );
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  return IDL.Service({
    'getClaimHistory' : IDL.Func([ClaimId], [IDL.Vec(FactRecord)], ['query']),
    'getFact' : IDL.Func([ClaimId], [IDL.Opt(FactRecord)], ['query']),
    'searchClaims' : IDL.Func([IDL.Text], [IDL.Vec(FactRecord)], ['query']),
    'storeFact' : IDL.Func(
        [
          ClaimId,
          IDL.Text,
          Verdict,
          IDL.Text,
          IDL.Vec(Evidence),
          IDL.Vec(IDL.Principal),
        ],
        [Result],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
