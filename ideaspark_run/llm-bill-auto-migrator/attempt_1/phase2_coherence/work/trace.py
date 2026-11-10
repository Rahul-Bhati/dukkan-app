# Coherence dry-run of "Disagreement-Restricted Certificates" (stdlib only).
# Executes the candidate's OWN rules (shells, exact weights, categorical shell selector with
# shared per-shell streams + label cache, anytime CS on mu_D, label-free p_d / mu_D slacks,
# fixed-sequence testing, budget B) on SYNTHETIC logs. No learned component is simulated:
# C, I, s_C and gold-label outcomes d are drawn synthetic inputs.
# Anytime CS used: predictable-plug-in empirical-Bernstein (WSR 2023), a betting-derived,
# variance-adaptive one-sided CS (stand-in for "the betting CS of n8"; my choice).
import math, random

def kl(p, q):
    q = min(max(q, 1e-15), 1 - 1e-15)
    t = 0.0
    if p > 0: t += p * math.log(p / q)
    if p < 1: t += (1 - p) * math.log((1 - p) / (1 - q))
    return t

def p_upper(k, n, d):
    ph = k / n; lo, hi = ph, 1.0
    for _ in range(60):
        m = (lo + hi) / 2
        if n * kl(ph, m) <= math.log(1 / d): lo = m
        else: hi = m
    return lo

def p_lower(k, n, d):
    ph = k / n; lo, hi = 0.0, ph
    for _ in range(60):
        m = (lo + hi) / 2
        if n * kl(ph, m) <= math.log(1 / d): hi = m
        else: lo = m
    return hi

class CS:  # one-sided PrPl-EB lower & upper CS for X in [-1,1] (via Y=(X+1)/2)
    def __init__(s, a):
        s.a = a; s.t = 0; s.sumY = 0.0; s.mu_prev = 0.5; s.var_acc = 0.25; s.sig_prev = 0.25
        s.sl = 0.0; s.slY = 0.0; s.pen = 0.0; s.lcb = -1.0; s.ucb = 1.0
    def update(s, x):
        y = (x + 1) / 2; s.t += 1; t = s.t
        lam = min(math.sqrt(2 * math.log(1 / s.a) / (s.sig_prev * t * math.log(1 + t))), 0.5)
        v = 4 * (y - s.mu_prev) ** 2
        s.sl += lam; s.slY += lam * y; s.pen += v * (-math.log(1 - lam) - lam) / 4
        s.sumY += y; mu = (0.5 + s.sumY) / (t + 1)
        s.var_acc += (y - mu) ** 2; s.sig_prev = s.var_acc / (t + 1); s.mu_prev = mu
        c = s.slY / s.sl; w = (math.log(1 / s.a) + s.pen) / s.sl
        s.lcb = max(s.lcb, 2 * (c - w) - 1); s.ucb = min(s.ucb, 2 * (c + w) - 1)

NEG_INF = float('-inf')

def make_pop(qf, af, bf, K=20):
    # discrete P: s-bins (k+.5)/K equiprobable; q=P(C!=I|s); on disagreements a=P(d=+1), b=P(d=-1)
    return [((k + .5) / K, 1 / K, qf((k + .5) / K), af((k + .5) / K), bf((k + .5) / K)) for k in range(K)]

def delta_P(pop, tau):
    return sum(w * q * (a - b) for s, w, q, a, b in pop if s >= tau)

def pd_P(pop, tau):
    return sum(w * q for s, w, q, a, b in pop if s >= tau)

def draw_log(pop, N, rng):
    cells = [c for c in pop]; cum = []; acc = 0
    for c in cells: acc += c[1]; cum.append(acc)
    L = []
    for _ in range(N):
        u = rng.random(); k = 0
        while cum[k] < u and k < len(cum) - 1: k += 1
        s, w, q, a, b = cells[k]
        dis = rng.random() < q
        if dis:
            u2 = rng.random(); d = 1 if u2 < a else (-1 if u2 < a + b else 0)
        else:
            d = 0  # P1: agreement => d = 0 for any gold label
        L.append((s, dis, d))
    return L

def split_rule(pd, nD, N, delta, B):
    # READING (a): delta_pop = smallest share on a grid whose pop slack (in Delta units) is <= the
    # range-based label-term width at budget B -- label-free, fixed before any label is bought.
    for k in range(1, 400):
        dp = delta * k / 400; dl = delta - dp
        pu = p_upper(round(pd * N), N, dp / 2)
        slack = math.sqrt(2 * math.log(2 / dp) / nD)
        popw = pu * slack + (pu - pd)
        labw = pd * math.sqrt(2 * math.log(1 / dl) / B)
        if popw <= labw: return dp, popw, labw
    return delta * 399 / 400, popw, labw

def mechanism(L, taus, eps, delta, B, seed=0, mode='disagree', max_draws=300000, fixed_split=None, verbose=False):
    N = len(L); M = len(taus)
    def shell_of(s):
        for j, t in enumerate(taus):
            if s >= t: return j
        return None
    shells = [[] for _ in range(M)]
    for idx, (s, dis, d) in enumerate(L):
        j = shell_of(s)
        if j is None: continue
        if mode == 'disagree' and not dis: continue
        shells[j].append(idx)
    w = [len(r) / N for r in shells]
    streams = [[] for _ in range(M)]; srng = [random.Random(seed * 7919 + i) for i in range(M)]
    cache = {}; out = []; tau_star = None; stopped = None
    for j in range(M):
        pd = sum(w[:j + 1]); nD = round(pd * N)
        if nD == 0:
            out.append(dict(j=j, pd=0.0, note='p_d=0: selector w_i/p_d is 0/0 and slack sqrt(.../|D_L|) divides by 0'))
            stopped = 'p_d=0 undefined'; break
        if fixed_split is None: dp, popw, labw = split_rule(pd, nD, N, delta, B)
        else: dp = fixed_split; popw = labw = None
        dl = delta - dp
        pu = p_upper(nD, N, dp / 2); plo = p_lower(nD, N, dp / 2)
        slack = math.sqrt(2 * math.log(2 / dp) / nD)
        cs = CS(dl); ptr = [0] * M; probs = [w[i] / pd for i in range(j + 1)]
        sel = random.Random(seed * 104729 + 31 * j); res = None; draws = 0; shellcount = [0] * (j + 1)
        while True:
            u = sel.random(); acc = 0; i = 0
            for i in range(j + 1):
                acc += probs[i]
                if u < acc: break
            k = ptr[i]; ptr[i] += 1; shellcount[i] += 1
            while len(streams[i]) <= k: streams[i].append(shells[i][srng[i].randrange(len(shells[i]))])
            idx = streams[i][k]
            if idx not in cache:
                if len(cache) >= B: res = 'budget'; break
                cache[idx] = L[idx][2]
            cs.update(cache[idx]); draws += 1
            b = cs.lcb - slack
            lb = (plo if b >= 0 else pu) * b
            ub_in = cs.ucb + slack
            ub = (pu if ub_in >= 0 else plo) * ub_in
            if lb >= -eps: res = 'certified'; break
            if ub < -eps: res = 'futile'; break
            if draws >= max_draws: res = 'NO_HALT(guard %d draws, labels=%d)' % (max_draws, len(cache)); break
        out.append(dict(j=j, tau=taus[j], pd=round(pd, 5), nD=nD, delta_pop=round(dp, 5), popw=popw and round(popw, 5),
                        labw=labw and round(labw, 5), slack_mu=round(slack, 4), p_up=round(pu, 5), lcb_mu=round(cs.lcb, 4),
                        lb_Delta=round(lb, 5), res=res, draws=draws, labels_cum=len(cache), shellcount=shellcount))
        if res == 'certified': tau_star = taus[j]
        else: stopped = res; break
    return tau_star, len(cache), out

def naive(L, taus, eps, delta, B, seed=0, max_draws=None):
    # constructed naive: one uniform without-replacement label stream over L (iid from P),
    # z = 1{s>=tau_j} d, same anytime CS at full delta, same fixed-sequence & budget, no partition/slack.
    rng = random.Random(seed + 555); order = list(range(len(L))); rng.shuffle(order)
    used = 0; tau_star = None; out = []
    for j, t in enumerate(taus):
        cs = CS(delta); res = None; n = 0
        while True:
            if n >= B or n >= len(L): res = 'budget'; break
            s, dis, d = L[order[n]]; n += 1; used = max(used, n)
            cs.update(d if s >= t else 0)
            if cs.lcb >= -eps: res = 'certified'; break
            if cs.ucb < -eps: res = 'futile'; break
        out.append(dict(j=j, tau=t, res=res, labels_cum=used, lcb=round(cs.lcb, 5)))
        if res == 'certified': tau_star = t
        else: break
    return tau_star, used, out

def declared_naive(L, taus, eps, delta, n, seed=0):
    # candidate's declared naive: n uniform gold labels, fixed-n Hoeffding lower bound on Delta, z in [-1,1]
    rng = random.Random(seed + 777); S = rng.sample(range(len(L)), n); tau_star = None; out = []
    h = math.sqrt(2 * math.log(1 / delta) / n)
    for t in taus:
        zbar = sum((L[i][2] if L[i][0] >= t else 0) for i in S) / n
        out.append((t, round(zbar - h, 5)))
        if zbar - h >= -eps: tau_star = t
        else: break
    return tau_star, out

print('=== T2 main instance (my illustrative values) ===')
eps, delta, B, N = 0.02, 0.05, 4000, 20000
taus = [0.8, 0.6, 0.4, 0.2, NEG_INF]
pop = make_pop(lambda s: 0.02 + 0.25 * (1 - s) ** 2, lambda s: 0.30 + 0.25 * s, lambda s: 0.25 + 0.35 * (1 - s))
for t in taus: print('tau=%s  p_d,P=%.5f  Delta_P=%.5f  mu_D,P=%.4f' % (t, pd_P(pop, t), delta_P(pop, t), delta_P(pop, t) / pd_P(pop, t)))
L = draw_log(pop, N, random.Random(1))
ts, lab, out = mechanism(L, taus, eps, delta, B, seed=1)
print('MECHANISM tau*=%s labels=%d' % (ts, lab))
for o in out: print('  ', o)
tn, labn, outn = naive(L, taus, eps, delta, B, seed=1)
print('CONSTRUCTED NAIVE tau*=%s labels=%d' % (tn, labn))
for o in outn: print('  ', o)
td, outd = declared_naive(L, taus, eps, delta, B, seed=1)
print('DECLARED NAIVE (Hoeffding, n=B=%d) tau*=%s  LBs=%s' % (B, td, outd))
print('declared-naive n needed at Delta=0: 2ln(1/delta)/eps^2 =', round(2 * math.log(1 / delta) / eps ** 2))

print('\n=== T2b negative control: shells = all of A(tau) (no disagreement restriction), same machinery ===')
tc, labc, outc = mechanism(L, taus, eps, delta, B, seed=1, mode='all')
print('ABLATED tau*=%s labels=%d' % (tc, labc))
for o in outc: print('  ', o)

print('\n=== selector uniformity check (hypothesis j=4): shell picks vs |R_i|/|D| ===')
o4 = out[-1] if out[-1]['j'] == 4 else None
if o4:
    sc = o4['shellcount']; tot = sum(sc)
    shells_sz = []
    for j in range(5):
        shells_sz.append(sum(1 for (s, dis, d) in L if dis and (s >= taus[j]) and (j == 0 or s < taus[j - 1])))
    print('  picks', sc, 'expected', [round(tot * x / sum(shells_sz)) for x in shells_sz])

print('\n=== width at fixed label count n (tau_M), range-based vs variance-adaptive ===')
pdM = sum(1 for r in L if r[1]) / N
dvals = [r[2] for r in L if r[1]]; muD = sum(dvals) / len(dvals); ED2 = sum(x * x for x in dvals) / len(dvals)
var_mech = pdM ** 2 * (ED2 - muD ** 2); var_unif = pdM * ED2 - (pdM * muD) ** 2
print('  p_d=%.4f mu_D=%.4f E_D[d^2]=%.4f  sd ratio mech/uniform=%.4f  p_d=%.4f sqrt(p_d)=%.4f' % (pdM, muD, ED2, math.sqrt(var_mech / var_unif), pdM, math.sqrt(pdM)))
for n in (500, 2000):
    rng = random.Random(9); D = [r for r in L if r[1]]
    cm = CS(delta); cu = CS(delta)
    for _ in range(n): cm.update(rng.choice(D)[2]); cu.update(rng.choice(L)[2])
    wm = pdM * (sum(r[2] for r in D) / len(D) - cm.lcb)
    wu = (sum(r[2] for r in L) / N - cu.lcb)
    print('  n=%d  EB-CS lower width: mech(p_d*(mu-LCB))=%.4f uniform=%.4f ratio=%.3f ; Hoeffding ratio = p_d = %.4f' % (n, wm, wu, wm / wu, pdM))

print('\n=== T3 probe p_d -> 1 (every call disagrees): "never worse on gold labels" ===')
pop1 = make_pop(lambda s: 1.0, lambda s: 0.40, lambda s: 0.38)
L1 = draw_log(pop1, N, random.Random(2)); t1 = [NEG_INF]
print('  Delta_P=%.4f' % delta_P(pop1, NEG_INF))
print('  mechanism:', mechanism(L1, t1, eps, delta, B, seed=2)[:2], mechanism(L1, t1, eps, delta, B, seed=2)[2][0]['slack_mu'], 'slack_mu*p_up (floor in Delta units) =', round(mechanism(L1, t1, eps, delta, B, seed=2)[2][0]['slack_mu'] * mechanism(L1, t1, eps, delta, B, seed=2)[2][0]['p_up'], 4))
print('  naive    :', naive(L1, t1, eps, delta, B, seed=2)[:2])
for NN in (20000, 200000):
    for dp in (0.0125, 0.025):
        print('  label-free floor sqrt(2 p_d ln(2/dpop)/|L|) at p_d=1,|L|=%d,dpop=%s: %.4f' % (NN, dp, math.sqrt(2 * math.log(2 / dp) / NN)))

print('\n=== T3 probe: p_d(tau_j)=0 ===')
L0 = [(0.5, False, 0) for _ in range(1000)]
print('  ', mechanism(L0, [NEG_INF], eps, delta, B)[2])
try:
    _ = [0 / 0.0]
except ZeroDivisionError as e:
    print('  selector prob w_i/p_d with p_d=0 -> ZeroDivisionError:', e)

print('\n=== T3 probe: D_L fully cached before budget (|D_L| < B), straddling band ===')
Ls = [(0.5, False, 0)] * 1960 + [(0.5, True, -1)] * 20 + [(0.5, True, 1)] * 6 + [(0.5, True, 0)] * 14
print('  |L|=%d |D_L|=40 mu_D,L=%.3f B=%d' % (len(Ls), (6 - 20) / 40, B))
r = mechanism(Ls, [NEG_INF], eps, delta, B, seed=3, max_draws=200000)
print('  ', r[0], r[1], r[2][0])
r2 = mechanism(Ls, [NEG_INF], eps, delta, 30, seed=3, max_draws=200000)
print('   same with B=30 (B<|D_L|):', r2[0], r2[1], r2[2][0]['res'])

print('\n=== break attempt: FWER with shared streams + optional stopping, boundary instance ===')
# tau_1 safe (Delta_P>=-eps), tau_2 unsafe (Delta_P = -eps - small). Violation = certify tau_2.
popb = make_pop(lambda s: 0.12 if s >= 0.5 else 0.30, lambda s: 0.45 if s >= 0.5 else 0.30, lambda s: 0.35 if s >= 0.5 else 0.505)
tb = [0.5, NEG_INF]
print('  Delta_P(tau1)=%.5f  Delta_P(tau2)=%.5f  (-eps=%.3f)' % (delta_P(popb, 0.5), delta_P(popb, NEG_INF), -eps))
R = 300; viol = 0; cert1 = 0; labs = []
for rep in range(R):
    Lb = draw_log(popb, 20000, random.Random(1000 + rep))
    ts_, lab_, o_ = mechanism(Lb, tb, eps, delta, 3000, seed=1000 + rep, fixed_split=0.0125)
    if ts_ is not None: cert1 += 1
    if ts_ == NEG_INF: viol += 1
    labs.append(lab_)
print('  reps=%d  certified tau1: %d  VIOLATIONS (certified unsafe tau2): %d  rate=%.4f  (delta=%.2f)  mean labels=%.0f' % (R, cert1, viol, viol / R, delta, sum(labs) / R))
