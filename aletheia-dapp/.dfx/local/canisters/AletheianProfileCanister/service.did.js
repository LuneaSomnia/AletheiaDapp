export const idlFactory = ({ IDL }) => {
  const Badge = IDL.Text;
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const Rank = IDL.Variant({
    'Junior' : IDL.Null,
    'Trainee' : IDL.Null,
    'Associate' : IDL.Null,
    'Senior' : IDL.Null,
    'Master' : IDL.Null,
    'Expert' : IDL.Null,
  });
  const PerformanceMetrics = IDL.Record({
    'claimsVerified' : IDL.Nat,
    'avgVerificationTime' : IDL.Nat,
    'escalationsResolved' : IDL.Nat,
    'accuracy' : IDL.Float64,
  });
  const Profile = IDL.Record({
    'xp' : IDL.Nat,
    'username' : IDL.Opt(IDL.Text),
    'createdAt' : IDL.Int,
    'badges' : IDL.Vec(Badge),
    'rank' : Rank,
    'warnings' : IDL.Nat,
    'performance' : PerformanceMetrics,
    'lastActive' : IDL.Int,
  });
  const Result_1 = IDL.Variant({ 'ok' : Profile, 'err' : IDL.Text });
  return IDL.Service({
    'addBadge' : IDL.Func([Badge], [Result], []),
    'createProfile' : IDL.Func([IDL.Opt(IDL.Text)], [Result], []),
    'getProfile' : IDL.Func([], [Result_1], ['query']),
    'updateProfile' : IDL.Func([IDL.Opt(IDL.Text)], [Result], []),
    'updateXP' : IDL.Func([IDL.Int], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
