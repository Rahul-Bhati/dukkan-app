# Supplementary probes (imports the rules from trace.py without re-running its main block).
import math, random, sys, io
src = open(__file__.replace('trace2.py', 'trace.py'), encoding='utf-8').read().split("print('=== T2 main instance")[0]
exec(src)
eps, delta = 0.02, 0.05
print('=== p_d = 1 regime: mechanism vs constructed naive, labels-to-decision (budget B = |L|) ===')
for (a, b, N) in [(0.44, 0.38, 20000), (0.45, 0.37, 20000), (0.44, 0.38, 100000)]:
    pop1 = make_pop(lambda s: 1.0, lambda s, a=a: a, lambda s, b=b: b)
    L1 = draw_log(pop1, N, random.Random(5))
    m = mechanism(L1, [NEG_INF], eps, delta, N, seed=5, max_draws=2000000)
    nv = naive(L1, [NEG_INF], eps, delta, N, seed=5)
    o = m[2][0]
    print('  N=%d Delta_P=%.3f | mech tau*=%s labels=%d delta_pop=%.4f delta_lab=%.5f slack_floor=%.4f res=%s | naive tau*=%s labels=%d'
          % (N, a - b, m[0], m[1], o['delta_pop'], delta - o['delta_pop'], o['slack_mu'] * o['p_up'], o['res'], nv[0], nv[1]))
print('\n=== split rule feasibility: popw <= labw at ANY delta_pop in (0, delta)? ratio ~ sqrt(B/nD * ln(2/dp)/ln(1/dl)) ===')
for (pd, N, B) in [(0.107, 20000, 4000), (0.107, 20000, 1000), (0.107, 200000, 4000), (0.01, 20000, 4000), (0.01, 1000000, 4000)]:
    nD = round(pd * N); feas = []
    for k in range(1, 400):
        dp = delta * k / 400; dl = delta - dp
        pu = p_upper(nD, N, dp / 2); popw = pu * math.sqrt(2 * math.log(2 / dp) / nD) + (pu - pd)
        labw = pd * math.sqrt(2 * math.log(1 / dl) / B)
        if popw <= labw: feas.append(dp)
    print('  p_d=%.3f |L|=%d B=%d nD=%d : feasible=%s first=%s' % (pd, N, B, nD, bool(feas), feas[0] if feas else None))
print('\n=== un-clamped bracket: LCB_D - slack below -1 ===')
pu = p_upper(107, 20000, 0.025); sl = math.sqrt(2 * math.log(2 / 0.05) / 107)
print('  p_d,L=0.00535 p_up=%.5f slack=%.4f  bound unclamped p_up*(-1-slack)=%.5f  clamped p_up*(-1)=%.5f' % (pu, sl, pu * (-1 - sl), -pu))
