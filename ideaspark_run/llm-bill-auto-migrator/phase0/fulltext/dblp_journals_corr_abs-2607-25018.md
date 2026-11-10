# Conformal Cascade: Distribution-Free Accuracy Guarantees for Multi-Tier LLM Inference

paper_id: dblp:journals/corr/abs-2607-25018
tier: H
source_used: html_arxiv
warning: none

## Intro

Deploying large language models at scale forces a sharp trade-off between answer quality and inference cost. Serving a frontier model on every query is often prohibitive: at current token prices, inference dominates the operating expense of any high-traffic product, and each expensive call consumes accelerator time that could serve simpler queries cheaply elsewhere. LLM cascades offer the dominant production response: a query runs first on a small model, and escalates to a larger one only when needed
(
Chen et al., 2023
;
Ong et al., 2025
;
Aggarwal et al., 2024
)
. What determines whether a cascade works is the
deferral rule
: at each tier, the decision to return the current answer or hand the query to the next model. Production cascades implement this decision as a threshold on a confidence signal such as softmax probability
(
Ong et al., 2025
)
, self-consistency agreement
(
Wang et al., 2023
;
Valkanas et al., 2025
)
, or a learned router score
(
Shnitzer et al., 2023
)
: accept if the signal exceeds a cutoff
θ
\theta
, defer otherwise.
Confidence-threshold deferral has a well-documented calibration problem. LLMs are overconfident in ways that depend on domain and input format, sharpest on the reasoning-heavy queries that benefit most from escalation
(
Kadavath et al., 2022
;
Xiong et al., 2024
)
, and no choice of
θ
\theta
separates confidently-wrong inputs from genuinely easy ones. The deeper issue is that the cascade’s error rate becomes an uncontrolled random variable: realized accuracy depends on the unknown joint distribution of queries, confidences, and correctness, and no analytical relationship maps a target error rate onto a threshold. Practitioners cannot answer the question that matters for deployment, “if I promise my users at most
5
%
5\%
wrong answers, what should
θ
\theta
be?”, and must re-sweep
θ
\theta
on a labelled split for every new model pair, benchmark, or difficulty distribution.
We propose
Conformal Cascade
(CC), which replaces the confidence threshold with a
conformal prediction set
. At each tier, split conformal calibration
(
Vovk et al., 2005
;
Papadopoulos et al., 2002
)
turns a held-out labelled set into a threshold that satisfies a distribution-free coverage guarantee
at that tier
: for any new query, the per-tier prediction set built from this threshold contains the correct answer with probability at least
1
−
α
1-\alpha
, for a user-specified
α
\alpha
. The
size
of this set, not the value of a confidence score, drives deferral. A set that collapses to a single answer declares the model conformally certain on this input, and the cascade accepts; a set with multiple candidates declares the model conformally uncertain, and the cascade escalates. Deferral cannot itself cause an error: only the acceptance event
|
𝒞
|
=
1
|\mathcal{C}|=1
commits a wrong answer, so the conformal guarantee binds at whichever tier the cascade commits, and per-tier guarantees compose into a cascade-level coverage bound. The calibrated threshold is fully determined by
α
\alpha
, which reads directly as the user’s error budget, and the expected cascade cost is a closed-form function of
α
\alpha
and the calibration-set acceptance rate.
We make three contributions. We formulate the conformal cascade for arbitrary
K
K
tiers, where prediction-set size replaces the confidence score, and prove a cascade-level coverage bound (Theorem
2
): the accepting tier’s prediction set covers the correct answer with probability at least
1
−
K
​
α
1-K\alpha
in the worst case, tightening to
1
−
α
1-\alpha
under a selection-preservation condition consistent with our marginal-coverage measurements. We then derive a closed-form expression for expected cascade cost as a function of
α
\alpha
(Theorem
4
). Empirically, we evaluate two-tier instantiations (
K
=
2
K=2
) across four open-weight model families (Llama, Gemma, Ministral, Phi) and 18 multiple-choice benchmarks; CC strictly improves over the strongest calibration-tuned heuristic cascade on the majority of family–benchmark pairs, with the largest gains on reasoning-heavy tasks where majority vote is unreliable: examples include Ministral on MathQA, Phi on GPQA-Diamond and MedMCQA, and Gemma on TruthfulQA. The framework requires a finite, extractable answer set; extension to open-ended generation through answer clustering is left for future work. The method imposes no architectural constraints beyond self-consistency-style sampling, requires neither training nor logprob access, and exposes one interpretable hyperparameter.

## Method

We describe each component of the Conformal Cascade. Sections
3.1
–
3.2
introduce the black-box nonconformity score and its per-tier calibration. Section
3.3
states the cascade algorithm. Sections
3.4
–
3.5
establish the cascade-level coverage guarantee and the cost–accuracy trade-off. Proofs, auxiliary lemmas, and the computational-complexity breakdown are collected in Appendix
L
.
The core idea is to replace the signal-plus-threshold deferral rule of Section
1
with a calibrated prediction set at each tier, whose size is the signal. A confidence threshold
θ
\theta
has no formal tie to an error rate; the conformal threshold
q
^
k
\hat{q}_{k}
has the tie supplied by Theorem
1
. The user-specified parameter
α
\alpha
then appears in two roles: as a coverage level (Theorem
2
) and as a handle on expected cost (Theorem
4
).
3.1
Frequency-Based Nonconformity Score
Split conformal prediction (Theorem
1
) requires a real-valued nonconformity score on
(
x
,
a
)
(x,a)
but is silent about where the score comes from. Under black-box API access, where token-level probabilities are typically not exposed, the natural choice is the sampling frequency of
a
a
under repeated decoding from
m
k
m_{k}
. A logprob-based variant
s
k
​
(
x
,
a
)
=
1
−
p
k
​
(
a
∣
x
)
s_{k}(x,a)=1-p_{k}(a\mid x)
slots into the same framework with finer resolution; we develop the frequency version because it preserves the black-box interface assumed by many production deployments and discuss the comparison to the logprob alternative in Appendix
L.1
.
For tier
k
k
, we draw
N
N
independent responses from
m
k
m_{k}
at temperature
τ
>
0
\tau>0
(the self-consistency regime of
Wang et al. (2023)
), giving extracted answers
y
^
1
(
k
)
,
…
,
y
^
N
(
k
)
\hat{y}_{1}^{(k)},\ldots,\hat{y}_{N}^{(k)}
. When the answer set
𝒜
⁡
(
x
)
\mathcal{A}(x)
varies per query (TruthfulQA has
|
𝒜
⁡
(
x
)
|
∈
{
4
,
…
,
10
}
|\mathcal{A}(x)|\in\{4,\ldots,10\}
), all quantities below are defined per-query on
𝒜
⁡
(
x
)
\mathcal{A}(x)
. The frequency-based nonconformity score for
a
∈
𝒜
⁡
(
x
)
a\in\mathcal{A}(x)
is
s
k
(
x
,
a
)
=
1
−
|
{
i
:
y
^
i
(
k
)
=
a
}
|
N
.
s_{k}(x,a)\;=\;1-\frac{\bigl|\{i:\hat{y}_{i}^{(k)}=a\}\bigr|}{N}.
(3)
An answer sampled often scores low (high conformity); a rarely sampled answer scores high (low conformity). The score uses only black-box API access, reuses the
N
N
samples already produced under self-consistency decoding, and composes naturally with a majority-vote tiebreaker when multiple answers survive calibration; its validity as a nonconformity measure follows
Kumar et al. (2023)
. Appendix
L.1
(Lemma
5
) certifies that exchangeability of queries lifts to exchangeability of scores under per-query independent Monte-Carlo draws.
3.2
Per-Tier Conformal Calibration
Calibration converts the score
s
k
s_{k}
into a prediction-set construction rule with a concrete coverage guarantee at level
α
\alpha
. For each tier
k
k
, we calibrate a threshold
q
^
k
\hat{q}_{k}
on a held-out calibration set
𝒟
cal
=
{
(
x
i
,
y
i
)
}
i
=
1
n
\mathcal{D}_{\mathrm{cal}}=\{(x_{i},y_{i})\}_{i=1}^{n}
by (i) drawing
N
N
samples from
m
k
m_{k}
for each calibration query and computing
s
i
(
k
)
=
s
k
​
(
x
i
,
y
i
)
s_{i}^{(k)}=s_{k}(x_{i},y_{i})
, (ii) sorting the scores
s
(
1
)
(
k
)
≤
s
(
2
)
(
k
)
≤
⋯
≤
s
(
n
)
(
k
)
s_{(1)}^{(k)}\leq s_{(2)}^{(k)}\leq\cdots\leq s_{(n)}^{(k)}
, and (iii) setting
q
^
k
=
s
(
⌈
(
1
−
α
)
​
(
n
+
1
)
⌉
)
(
k
)
\hat{q}_{k}=s_{(\lceil(1-\alpha)(n+1)\rceil)}^{(k)}
. The prediction set at tier
k
k
for a new query
x
x
is
𝒞
k
​
(
x
)
=
{
a
∈
𝒜
:
s
k
​
(
x
,
a
)
≤
q
^
k
}
.
\mathcal{C}_{k}(x)\;=\;\{a\in\mathcal{A}:s_{k}(x,a)\leq\hat{q}_{k}\}.
(4)
Operationally,
q
^
k
\hat{q}_{k}
is the smallest nonconformity score the calibration set permits at coverage level
α
\alpha
: answers scoring below it pass the conformal filter, those above are filtered out. By Theorem
1
, under exchangeability
Pr
[
y
true
∈
𝒞
k
(
x
)
]
≥
1
−
α
\mathrm{Pr}[y_{\mathrm{true}}\in\mathcal{C}_{k}(x)]\geq 1-\alpha
at each tier in isolation. Calibration-size choice, quantile tie-breaking, and computational complexity are detailed in Appendix
L.2
.
3.3
The Conformal Cascade Algorithm
With per-tier prediction sets in hand, the cascade asks one question at each tier: is the calibrated set small enough to commit on? Algorithm
1
specifies the procedure. An acceptance threshold
κ
≥
1
\kappa\geq 1
governs how small a set counts as a commitment (default
κ
=
1
\kappa=1
).
Algorithm 1
Conformal Cascade (CC)
1:
Query
x
x
; models
m
1
,
…
,
m
K
m_{1},\ldots,m_{K}
; calibrated thresholds
q
^
1
,
…
,
q
^
K
\hat{q}_{1},\ldots,\hat{q}_{K}
; acceptance parameter
κ
\kappa
2:
Answer
y
^
\hat{y}
, accepting tier
k
∗
k^{*}
3:
for
k
=
1
,
…
,
K
k=1,\ldots,K
do
4:
Draw
N
N
samples from
m
k
m_{k}
on
x
x
5:
Compute
s
k
​
(
x
,
a
)
s_{k}(x,a)
for each
a
∈
𝒜
a\in\mathcal{A}
⊳
\triangleright
Eq. (
3
)
6:
Construct
𝒞
k
​
(
x
)
=
{
a
∈
𝒜
:
s
k
​
(
x
,
a
)
≤
q
^
k
}
\mathcal{C}_{k}(x)=\{a\in\mathcal{A}:s_{k}(x,a)\leq\hat{q}_{k}\}
⊳
\triangleright
Eq. (
4
)
7:
if
1
≤
|
𝒞
k
​
(
x
)
|
≤
κ
1\leq|\mathcal{C}_{k}(x)|\leq\kappa
then
8:
y
^
←
arg
⁡
min
a
∈
𝒞
k
​
(
x
)
​
s
k
​
(
x
,
a
)
\hat{y}\leftarrow\arg\min_{a\in\mathcal{C}_{k}(x)}s_{k}(x,a)
⊳
\triangleright
Most frequent answer in set
9:
return
y
^
,
k
∗
=
k
\hat{y},k^{*}=k
10:
end
if
11:
end
for
12:
y
^
←
arg
⁡
min
a
∈
𝒜
​
s
K
​
(
x
,
a
)
\hat{y}\leftarrow\arg\min_{a\in\mathcal{A}}s_{K}(x,a)
⊳
\triangleright
Fallback at last tier
13:
return
y
^
,
k
∗
=
K
\hat{y},k^{*}=K
Interpretation.
The set size measures tier-level uncertainty through the conformal filter. A set of size one (the cascade accepts, the model is
conformally certain
) commits to an answer; size larger than
κ
\kappa
(
conformally uncertain
) escalates. An empty set is an out-of-distribution signal and is also treated as a defer. Relaxed acceptance (
κ
>
1
\kappa>1
) accepts when the set is merely small, breaks argmin ties lexicographically on
𝒜
\mathcal{A}
, and trades a controlled amount of correctness for earlier acceptance (Section
3.5
). Our implementation runs the fallback (line 11) over
𝒞
K
​
(
x
)
\mathcal{C}_{K}(x)
when
|
𝒞
K
​
(
x
)
|
≥
1
|\mathcal{C}_{K}(x)|\geq 1
and over
𝒜
\mathcal{A}
only when the tier-
K
K
set is empty; this affects boundary behaviour on benchmarks where the cascade defers all queries but does not change the offline coverage guarantee (Appendix
H
).
Worked example.
Consider a 4-choice query
x
x
on which tier-1 self-consistency draws (
N
=
16
N=16
) yield extracted-answer counts
{
A
:
10
,
B
:
4
,
C
:
1
,
D
:
1
}
\{A:10,B:4,C:1,D:1\}
and tier-1 score values
s
1
​
(
x
,
A
)
=
6
/
16
,
s
1
​
(
x
,
B
)
=
12
/
16
,
s
1
​
(
x
,
C
)
=
15
/
16
,
s
1
​
(
x
,
D
)
=
15
/
16
s_{1}(x,A)=6/16,s_{1}(x,B)=12/16,s_{1}(x,C)=15/16,s_{1}(x,D)=15/16
. With a tight calibrated threshold
q
^
1
=
0.50
\hat{q}_{1}=0.50
(a small
α
\alpha
), only
A
A
passes:
𝒞
1
​
(
x
)
=
{
A
}
\mathcal{C}_{1}(x)=\{A\}
, the cascade accepts at tier 1, and the per-query cost is
c
1
c_{1}
. With a looser
q
^
1
=
0.80
\hat{q}_{1}=0.80
, the set becomes
𝒞
1
​
(
x
)
=
{
A
,
B
}
\mathcal{C}_{1}(x)=\{A,B\}
: the cascade defers under
κ
=
1
\kappa=1
and pays
c
1
+
c
2
c_{1}+c_{2}
, but with
κ
=
2
\kappa=2
it accepts and returns
arg
⁡
min
a
∈
{
A
,
B
}
​
s
1
​
(
x
,
a
)
=
A
\arg\min_{a\in\{A,B\}}s_{1}(x,a)=A
. The same query commits at tier 1 or escalates depending on
α
\alpha
and
κ
\kappa
; the conformal threshold turns the raw frequency distribution into a calibrated commit/defer signal.
3.4
Theoretical Analysis
Let
K
∗
​
(
x
)
∈
{
1
,
…
,
K
}
K^{*}(x)\in\{1,\ldots,K\}
denote the first tier at which the cascade commits in Algorithm
1
(defined as
K
K
when the fallback fires), and let
A
=
{
|
𝒞
K
∗
​
(
x
)
(
x
)
|
=
1
}
A=\{|\mathcal{C}_{K^{*}(x)}(x)|=1\}
be the
acceptance event
.
Theorem 2
(Cascade coverage)
.
Let
(
x
,
y
true
)
(x,y_{\mathrm{true}})
be exchangeable with each tier-
k
k
calibration set, for
k
=
1
,
…
,
K
k=1,\ldots,K
. In a
K
K
-tier Conformal Cascade with per-tier level
α
\alpha
and acceptance parameter
κ
=
1
\kappa=1
,
Pr
⁡
[
y
^
≠
y
true
,
A
]
≤
K
⋅
α
,
\mathrm{Pr}\!\left[\,\hat{y}\neq y_{\mathrm{true}},\,A\,\right]\;\leq\;K\cdot\alpha,
(5)
so per-tier level
α
/
K
\alpha/K
ensures cascade error at most
α
\alpha
.
The proof partitions
A
A
into the
K
K
disjoint first-commit events
A
k
=
{
K
∗
(
x
)
=
k
}
A_{k}=\{K^{*}(x)=k\}
and applies Theorem
1
on each (Appendix
L.3
). Two facts about the bound matter for practice. Deferral cannot itself cause an error: only the acceptance event
A
A
commits a wrong answer, escalation only incurs additional cost, and the cascade error decomposes over the disjoint commit events
{
A
k
}
k
=
1
K
\{A_{k}\}_{k=1}^{K}
. Per-tier guarantees therefore compose into a cascade-level bound by a union bound on these disjoint events. The factor
K
K
is the union-bound worst case; tighter statements hold under selective-inference conditions
(
Bates et al., 2023
;
Angelopoulos and Bates, 2023
)
, captured by the next assumption.
Assumption 3
(Selection preservation)
.
For each tier
k
k
,
Pr
⁡
[
y
true
∈
𝒞
k
​
(
x
)
∣
K
∗
​
(
x
)
=
k
]
≥
1
−
α
\mathrm{Pr}[\,y_{\mathrm{true}}\in\mathcal{C}_{k}(x)\mid K^{*}(x)=k\,]\geq 1-\alpha
.
Under Assumption
3
the cascade error is bounded by
α
\alpha
directly. The first-commit event
{
K
∗
(
x
)
=
k
}
\{K^{*}(x)=k\}
is label-free—a function of
x
x
and the calibration scores, not
y
true
y_{\mathrm{true}}
—which places it in the family studied by selective conformal inference; the assumption asks that this label-free selection preserve per-tier coverage, and is not derivable from split CP alone. Section
5.3
reports marginal miscoverage tracking
α
\alpha
rather than
K
​
α
K\alpha
, which rules out the
K
​
α
K\alpha
bound being tight here but is only
consistent with
, not strictly implied by, Assumption
3
(which would require per-tier conditional miscoverage). Two further notes on scope: Theorem
2
bounds the joint event {error, acceptance}; on the fallback path the cascade returns an argmin without an active conformal commit and inherits no per-tier guarantee (rare in practice—Appendix
H
). For
κ
>
1
\kappa>1
the union bound controls
set
coverage, and the top-1 error picks up an additional slack from the argmin tiebreaker (Remark
8
, Appendix
L.3
). The relaxed-acceptance variant and the heterogeneous-
α
k
\alpha_{k}
extension are also in Appendix
L.3
.
3.5
Cost–Coverage Trade-off
The accuracy guarantee comes paired with a closed-form expression for expected cost.
Theorem 4
(Cost–coverage, two-tier)
.
For a two-tier cascade
(
K
=
2
)
(K=2)
with costs
c
1
<
c
2
c_{1}<c_{2}
and
κ
=
1
\kappa=1
,
𝔼
[
Cost
(
X
)
]
=
c
1
+
c
2
⋅
Pr
[
|
𝒞
1
(
X
)
|
≠
1
]
.
\mathbb{E}[\mathrm{Cost}(X)]\;=\;c_{1}+c_{2}\cdot\mathrm{Pr}\!\left[\,|\mathcal{C}_{1}(X)|\neq 1\,\right].
(6)
Expected cost depends only on the calibration-set non-acceptance rate, which is observable on labelled calibration data without further test queries. The asymptotes are clean: as
α
→
0
\alpha\to 0
prediction sets grow and cost approaches
c
1
+
c
2
c_{1}+c_{2}
; as
α
→
1
\alpha\to 1
sets shrink to singletons and cost approaches
c
1
c_{1}
. Cost is monotone in
α
\alpha
on the admissible range, and the cascade strictly improves over the always-defer baseline (
𝔼
⁡
[
Cost
]
<
c
1
+
c
2
\mathbb{E}[\mathrm{Cost}]<c_{1}+c_{2}
) whenever the cheap model produces any singleton sets on calibration (Proposition
10
). Improving over Always-Strong (which skips tier 1 and pays
c
2
c_{2}
) requires the stricter condition
Pr
[
|
𝒞
1
(
X
)
|
=
1
]
>
c
1
/
c
2
\mathrm{Pr}[|\mathcal{C}_{1}(X)|=1]>c_{1}/c_{2}
, since the cascade pays
c
1
c_{1}
per query for the tier-1 samples regardless of whether they trigger acceptance.
For
K
>
2
K>2
tiers,
𝔼
⁡
[
Cost
⁡
(
X
)
]
=
∑
k
=
1
K
(
∑
j
=
1
k
c
j
)
⋅
p
k
\mathbb{E}[\mathrm{Cost}(X)]=\sum_{k=1}^{K}(\sum_{j=1}^{k}c_{j})\cdot p_{k}
with
p
k
=
Pr
[
K
∗
(
X
)
=
k
]
p_{k}=\mathrm{Pr}[K^{*}(X)=k]
(Corollary
11
, appendix). Combined with Theorem
2
, this gives a practitioner recipe: for a target cascade error rate
β
\beta
, set
α
=
β
/
K
\alpha=\beta/K
in the worst case or
α
=
β
\alpha=\beta
under Assumption
3
as a deployment heuristic (Remark
12
, appendix; finite-
N
N
monotonicity is checked by a small calibration sweep, Appendix
J
). The user fixes the error budget; the cascade picks the threshold.
Concretely, with
K
=
2
K=2
and
c
1
=
1
c_{1}=1
,
c
2
=
2.7
c_{2}=2.7
, an
80
%
80\%
calibration acceptance rate gives
𝔼
⁡
[
Cost
]
=
1.54
\mathbb{E}[\mathrm{Cost}]=1.54
(
43
%
43\%
saving over Always-Strong); the saving as a function of cost ratio
r
=
c
2
/
c
1
r=c_{2}/c_{1}
is in Appendix
J
.
