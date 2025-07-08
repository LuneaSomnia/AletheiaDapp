export const idlFactory = ({ IDL }) => {
  const ClaimId = IDL.Text;
  const ClaimType = IDL.Variant({
    'Url' : IDL.Null,
    'Link' : IDL.Null,
    'Text' : IDL.Null,
    'Image' : IDL.Null,
    'Audio' : IDL.Null,
    'Video' : IDL.Null,
  });
  const Claim = IDL.Record({
    'id' : ClaimId,
    'status' : IDL.Variant({
      'Processing' : IDL.Null,
      'Completed' : IDL.Null,
      'Pending' : IDL.Null,
    }),
    'content' : IDL.Text,
    'context' : IDL.Opt(IDL.Text),
    'source' : IDL.Opt(IDL.Text),
    'userId' : IDL.Principal,
    'submittedAt' : IDL.Int,
    'claimType' : ClaimType,
  });
  const Event = IDL.Variant({
    'ClaimStatusUpdated' : IDL.Record({
      'id' : ClaimId,
      'oldStatus' : IDL.Variant({
        'Processing' : IDL.Null,
        'Completed' : IDL.Null,
        'Pending' : IDL.Null,
      }),
      'newStatus' : IDL.Variant({
        'Processing' : IDL.Null,
        'Completed' : IDL.Null,
        'Pending' : IDL.Null,
      }),
    }),
    'ClaimSubmitted' : Claim,
  });
  const Result = IDL.Variant({ 'ok' : ClaimId, 'err' : IDL.Text });
  return IDL.Service({
    'addEventListener' : IDL.Func([IDL.Func([Event], [], ['oneway'])], [], []),
    'getClaim' : IDL.Func([ClaimId], [IDL.Opt(Claim)], ['query']),
    'getUserClaims' : IDL.Func([IDL.Nat, IDL.Nat], [IDL.Vec(Claim)], ['query']),
    'removeEventListener' : IDL.Func(
        [IDL.Func([Event], [], ['oneway'])],
        [],
        [],
      ),
    'submitClaim' : IDL.Func(
        [IDL.Text, ClaimType, IDL.Opt(IDL.Text), IDL.Opt(IDL.Text)],
        [Result],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
