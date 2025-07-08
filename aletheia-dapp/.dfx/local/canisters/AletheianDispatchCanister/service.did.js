export const idlFactory = ({ IDL }) => {
  const ClaimId = IDL.Text;
  const Claim = IDL.Record({
    'id' : ClaimId,
    'complexity' : IDL.Text,
    'content' : IDL.Text,
    'submittedAt' : IDL.Int,
    'category' : IDL.Opt(IDL.Text),
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const AletheianId = IDL.Principal;
  const Result_1 = IDL.Variant({ 'ok' : IDL.Nat, 'err' : IDL.Text });
  const AletheianProfile = IDL.Record({
    'id' : AletheianId,
    'status' : IDL.Text,
    'reputation' : IDL.Nat,
    'expertise' : IDL.Vec(IDL.Text),
    'lastActive' : IDL.Int,
    'location' : IDL.Opt(IDL.Text),
  });
  return IDL.Service({
    'addClaim' : IDL.Func([Claim], [Result], []),
    'assignClaims' : IDL.Func([], [Result], []),
    'getWorkload' : IDL.Func([AletheianId], [Result_1], []),
    'registerAletheian' : IDL.Func([AletheianProfile], [Result], []),
    'updateAletheianStatus' : IDL.Func([AletheianId, IDL.Text], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
