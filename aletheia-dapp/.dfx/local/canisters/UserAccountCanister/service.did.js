export const idlFactory = ({ IDL }) => {
  const Result_1 = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const ClaimId = IDL.Text;
  const UserProfile = IDL.Record({
    'username' : IDL.Opt(IDL.Text),
    'submittedClaims' : IDL.Vec(ClaimId),
    'createdAt' : IDL.Int,
    'learningPoints' : IDL.Nat,
    'lastActive' : IDL.Int,
  });
  const Result = IDL.Variant({ 'ok' : UserProfile, 'err' : IDL.Text });
  return IDL.Service({
    'addLearningPoints' : IDL.Func([IDL.Nat], [Result_1], []),
    'addSubmittedClaim' : IDL.Func([ClaimId], [Result_1], []),
    'createProfile' : IDL.Func([IDL.Opt(IDL.Text)], [Result_1], []),
    'getProfile' : IDL.Func([], [Result], ['query']),
  });
};
export const init = ({ IDL }) => { return []; };
