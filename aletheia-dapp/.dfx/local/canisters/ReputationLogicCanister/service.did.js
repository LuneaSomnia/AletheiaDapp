export const idlFactory = ({ IDL }) => {
  const AletheianId = IDL.Principal;
  const PerformanceMetrics = IDL.Record({
    'claimsVerified' : IDL.Nat,
    'avgVerificationTime' : IDL.Nat,
    'escalationsResolved' : IDL.Nat,
    'accuracy' : IDL.Float64,
  });
  const Rank = IDL.Variant({
    'Junior' : IDL.Null,
    'Trainee' : IDL.Null,
    'Associate' : IDL.Null,
    'Senior' : IDL.Null,
    'Master' : IDL.Null,
    'Expert' : IDL.Null,
  });
  const Action = IDL.Variant({
    'TrainingComplete' : IDL.Null,
    'CouncilResolution' : IDL.Null,
    'AccuracyBonus' : IDL.Null,
    'DuplicateIdentification' : IDL.Null,
    'SuccessfulVerification' : IDL.Null,
    'EscalationReview' : IDL.Null,
    'Mentoring' : IDL.Null,
    'SpeedBonus' : IDL.Null,
    'ComplexityBonus' : IDL.Nat,
    'Penalty' : IDL.Nat,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Nat, 'err' : IDL.Text });
  return IDL.Service({
    'getPerformance' : IDL.Func(
        [AletheianId],
        [IDL.Opt(PerformanceMetrics)],
        ['query'],
      ),
    'getRank' : IDL.Func([AletheianId], [IDL.Opt(Rank)], ['query']),
    'getWarnings' : IDL.Func([AletheianId], [IDL.Opt(IDL.Nat)], ['query']),
    'getXP' : IDL.Func([AletheianId], [IDL.Opt(IDL.Nat)], ['query']),
    'initializeAletheian' : IDL.Func([AletheianId], [], []),
    'updatePerformance' : IDL.Func(
        [
          AletheianId,
          IDL.Variant({
            'EscalationsResolved' : IDL.Nat,
            'VerificationTime' : IDL.Nat,
            'ClaimsVerified' : IDL.Nat,
            'Accuracy' : IDL.Float64,
          }),
        ],
        [],
        [],
      ),
    'updateXP' : IDL.Func([AletheianId, Action], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
