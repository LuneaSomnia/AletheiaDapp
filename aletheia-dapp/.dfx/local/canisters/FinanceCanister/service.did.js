export const idlFactory = ({ IDL }) => {
  const ICP = IDL.Nat;
  const AletheianId = IDL.Principal;
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  return IDL.Service({
    'addToPool' : IDL.Func([ICP], [], []),
    'distributePaymentPool' : IDL.Func([], [], []),
    'recordXp' : IDL.Func([AletheianId, IDL.Nat], [], []),
    'withdraw' : IDL.Func([ICP], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
