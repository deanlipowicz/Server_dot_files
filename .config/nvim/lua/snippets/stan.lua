local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("stan", {

  -- === Program structure ===

  s("prog-blocks", fmt([[
functions {{
  {1}
}}
data {{
  {2}
}}
transformed data {{
  {3}
}}
parameters {{
  {4}
}}
transformed parameters {{
  {5}
}}
model {{
  {6}
}}
generated quantities {{
  {7}
}}
]], { i(1), i(2), i(3), i(4), i(5), i(6), i(7) })),

  s("prog-data", fmt([[
data {{
  int<lower=0> {1};
  int<lower=0> {2};
  matrix[{1}, {2}] {3};
  vector[{1}] {4};
}}
]], { i(1, "N"), i(2, "K"), i(3, "X"), i(4, "y") })),

  s("prog-params", fmt([[
parameters {{
  real {1};
  vector[{2}] {3};
  real<lower=0> {4};
}}
]], { i(1, "alpha"), i(2, "K"), i(3, "beta"), i(4, "sigma") })),

  s("prog-model", fmt([[
model {{
  {1} ~ normal(0, {2});
  {3} ~ normal(0, {4});
  {5} ~ exponential(1);
  {6} ~ normal({1} + {7} * {3}, {5});
}}
]], { i(1, "alpha"), i(2, "5"), i(3, "beta"), i(4, "2.5"),
     i(5, "sigma"), i(6, "y"), i(7, "X") })),

  s("prog-gq", fmt([[
generated quantities {{
  vector[{1}] {2} = normal_rng({3} + {4} * {5}, {6});
  real log_lik = normal_lpdf({7} | {3} + {4} * {5}, {6});
}}
]], { i(1, "N"), i(2, "y_rep"), i(3, "alpha"), i(4, "X"), i(5, "beta"), i(6, "sigma"), i(7, "y") })),

  s("prog-tdata", fmt([[
transformed data {{
  real alpha_prior_scale = {1};
  vector[{2}] beta_prior_scale = rep_vector({3}, {2});
}}
]], { i(1, "10"), i(2, "K"), i(3, "5") })),

  -- === Declarations ===

  s("decl-int", fmt([[
int<lower=0> {1};
int<lower=0, upper=1> {2}[{3}];
]], { i(1, "N"), i(2, "y"), i(3, "N") })),

  s("decl-real", fmt([[
real<lower=0> {1};
real<lower=0, upper=1> {2};
]], { i(1, "sigma"), i(2, "p") })),

  s("decl-vector", fmt([[
vector[{1}] {2};
row_vector[{1}] {3};
]], { i(1, "K"), i(2, "beta"), i(3, "rv") })),

  s("decl-matrix", fmt([[
matrix[{1}, {2}] {3};
]], { i(1, "N"), i(2, "K"), i(3, "X") })),

  s("decl-simplex", fmt([[
simplex[{1}] {2};
]], { i(1, "K"), i(2, "theta") })),

  s("decl-cov", fmt([[
cov_matrix[{1}] {2};
corr_matrix[{1}] {3};
cholesky_factor_cov[{1}] {4};
]], { i(1, "K"), i(2, "Sigma"), i(3, "Omega"), i(4, "L_Sigma") })),

  -- === Priors ===

  s("prior-norm", fmt([[
{1} ~ normal({2}, {3});
]], { i(1, "theta"), i(2, "0"), i(3, "1") })),

  s("prior-student", fmt([[
{1} ~ student_t({2}, {3}, {4});
]], { i(1, "theta"), i(2, "3"), i(3, "0"), i(4, "5") })),

  s("prior-cauchy", fmt([[
{1} ~ cauchy({2}, {3});
]], { i(1, "theta"), i(2, "0"), i(3, "5") })),

  s("prior-beta", fmt([[
{1} ~ beta({2}, {3});
]], { i(1, "theta"), i(2, "2"), i(3, "2") })),

  s("prior-gamma", fmt([[
{1} ~ gamma({2}, {3});
]], { i(1, "sigma"), i(2, "2"), i(3, "1") })),

  s("prior-horseshoe", fmt([[
{1} ~ normal(0, {2} * {3});
{2} ~ cauchy(0, 1);
{3} ~ cauchy(0, 1);
]], { i(1, "theta"), i(2, "lambda"), i(3, "tau") })),

  -- === Regression ===

  s("reg-lin", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  vector[N] {2};
}}
parameters {{
  real alpha;
  real beta;
  real<lower=0> sigma;
}}
model {{
  alpha ~ normal(0, 10);
  beta ~ normal(0, 5);
  sigma ~ exponential(1);
  {2} ~ normal(alpha + beta * {1}, sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(alpha + beta * {1}, sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  s("reg-multi", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> K;
  matrix[N, K] {1};
  vector[N] {2};
}}
parameters {{
  real alpha;
  vector[K] beta;
  real<lower=0> sigma;
}}
model {{
  alpha ~ normal(0, 5);
  beta ~ normal(0, 2.5);
  sigma ~ exponential(1);
  {2} ~ normal(alpha + {1} * beta, sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(alpha + {1} * beta, sigma);
}}
]], { i(1, "X"), i(2, "y") })),

  s("reg-robust", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  vector[N] {2};
}}
parameters {{
  real alpha;
  real beta;
  real<lower=0> sigma;
  real<lower=1> nu;
}}
model {{
  alpha ~ normal(0, 10);
  beta ~ normal(0, 5);
  sigma ~ exponential(1);
  nu ~ gamma(2, 0.1);
  {2} ~ student_t(nu, alpha + beta * {1}, sigma);
}}
generated quantities {{
  vector[N] y_rep = student_t_rng(nu, alpha + beta * {1}, sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  s("reg-logit", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> K;
  matrix[N, K] {1};
  array[N] int<lower=0, upper=1> {2};
}}
parameters {{
  vector[K] beta;
}}
model {{
  beta ~ normal(0, 2.5);
  {2} ~ bernoulli_logit({1} * beta);
}}
generated quantities {{
  array[N] int y_rep = bernoulli_logit_rng({1} * beta);
}}
]], { i(1, "X"), i(2, "y") })),

  s("reg-probit", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> K;
  matrix[N, K] {1};
  array[N] int<lower=0, upper=1> {2};
}}
parameters {{
  vector[K] beta;
}}
model {{
  beta ~ normal(0, 2.5);
  {2} ~ bernoulli(Phi({1} * beta));
}}
generated quantities {{
  array[N] int y_rep = bernoulli_rng(Phi({1} * beta));
}}
]], { i(1, "X"), i(2, "y") })),

  s("reg-poisson", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> K;
  matrix[N, K] {1};
  array[N] int<lower=0> {2};
}}
parameters {{
  vector[K] beta;
}}
model {{
  beta ~ normal(0, 2.5);
  {2} ~ poisson_log_glm({1}, beta);
}}
generated quantities {{
  array[N] int y_rep = poisson_log_rng({1} * beta);
}}
]], { i(1, "X"), i(2, "y") })),

  s("reg-negbin", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> K;
  matrix[N, K] {1};
  array[N] int<lower=0> {2};
}}
parameters {{
  vector[K] beta;
  real<lower=0> phi;
}}
model {{
  beta ~ normal(0, 2.5);
  phi ~ exponential(1);
  {2} ~ neg_binomial_2_log_glm({1}, beta, phi);
}}
generated quantities {{
  array[N] int y_rep = neg_binomial_2_rng(exp({1} * beta), phi);
}}
]], { i(1, "X"), i(2, "y") })),

  s("reg-multinom", fmt([[
data {{
  int<lower=1> N;
  int<lower=2> K;
  array[N] int<lower=1, upper=K> {1};
  matrix[N, K] {2};
}}
parameters {{
  matrix[K, K] beta;
}}
model {{
  to_vector(beta) ~ normal(0, 2.5);
  for (n in 1:N) {{
    {1}[n] ~ categorical(softmax({2}[n]' * beta));
  }}
}}
generated quantities {{
  array[N] int y_rep;
  for (n in 1:N) {{
    y_rep[n] = categorical_rng(softmax({2}[n]' * beta));
  }}
}}
]], { i(1, "y"), i(2, "X") })),

  s("reg-ordinal", fmt([[
data {{
  int<lower=2> K;
  int<lower=0> N;
  int<lower=1, upper=K> {1}[N];
  int<lower=0> P;
  matrix[N, P] {2};
}}
parameters {{
  vector[P] beta;
  ordered[K-1] c;
}}
model {{
  beta ~ normal(0, 2.5);
  {1} ~ ordered_logistic({2} * beta, c);
}}
generated quantities {{
  int y_rep[N];
  y_rep = ordered_logistic_rng({2} * beta, c);
}}
]], { i(1, "y"), i(2, "X") })),

  s("reg-nonlin", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  vector[N] {2};
}}
parameters {{
  real alpha;
  real beta;
  real<lower=0> sigma;
}}
model {{
  alpha ~ normal(0, 10);
  beta ~ normal(0, 5);
  sigma ~ exponential(1);
  {2} ~ normal(alpha * exp(-beta * {1}), sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(alpha * exp(-beta * {1}), sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  -- === Hierarchical models ===

  s("hlm-vary-int", fmt([[
data {{
  int<lower=0> N;
  int<lower=1> J;
  array[N] int<lower=1, upper=J> group;
  vector[N] {1};
  vector[N] {2};
}}
parameters {{
  real beta;
  real<lower=0> sigma;
  real mu_alpha;
  real<lower=0> sigma_alpha;
  vector[J] alpha_j;
}}
model {{
  alpha_j ~ normal(mu_alpha, sigma_alpha);
  mu_alpha ~ normal(0, 5);
  sigma_alpha ~ exponential(1);
  sigma ~ exponential(1);
  {2} ~ normal(alpha_j[group] + beta * {1}, sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(alpha_j[group] + beta * {1}, sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  s("hlm-vary-slope", fmt([[
data {{
  int<lower=0> N;
  int<lower=1> J;
  array[N] int<lower=1, upper=J> group;
  vector[N] {1};
  vector[N] {2};
}}
parameters {{
  real alpha;
  real<lower=0> sigma;
  real mu_beta;
  real<lower=0> sigma_beta;
  vector[J] beta_j;
}}
model {{
  beta_j ~ normal(mu_beta, sigma_beta);
  mu_beta ~ normal(0, 5);
  sigma_beta ~ exponential(1);
  sigma ~ exponential(1);
  {2} ~ normal(alpha + beta_j[group] .* {1}, sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(alpha + beta_j[group] .* {1}, sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  s("hlm-noncent", fmt([[
data {{
  int<lower=0> N;
  int<lower=1> J;
  array[N] int<lower=1, upper=J> group;
  vector[N] {1};
  vector[N] {2};
}}
parameters {{
  real beta;
  real<lower=0> sigma;
  real mu_alpha;
  real<lower=0> sigma_alpha;
  vector[J] alpha_j_raw;
}}
transformed parameters {{
  vector[J] alpha_j = mu_alpha + sigma_alpha * alpha_j_raw;
}}
model {{
  alpha_j_raw ~ std_normal();
  mu_alpha ~ normal(0, 5);
  sigma_alpha ~ exponential(1);
  sigma ~ exponential(1);
  {2} ~ normal(alpha_j[group] + beta * {1}, sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(alpha_j[group] + beta * {1}, sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  s("hlm-2lev", fmt([[
data {{
  int<lower=0> N;
  int<lower=1> J;
  array[N] int<lower=1, upper=J> group;
  int<lower=1> P;
  int<lower=1> Q;
  matrix[N, P] {1};
  matrix[J, Q] {2};
  vector[N] {3};
}}
parameters {{
  vector[P] beta;
  real<lower=0> sigma;
  vector[Q] gamma;
  real<lower=0> sigma_alpha;
  vector[J] alpha_j_raw;
}}
transformed parameters {{
  vector[J] alpha_j = {2} * gamma + sigma_alpha * alpha_j_raw;
}}
model {{
  alpha_j_raw ~ std_normal();
  beta ~ normal(0, 2.5);
  gamma ~ normal(0, 2.5);
  sigma ~ exponential(1);
  sigma_alpha ~ exponential(1);
  {3} ~ normal({1} * beta + alpha_j[group], sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng({1} * beta + alpha_j[group], sigma);
}}
]], { i(1, "X"), i(2, "Z"), i(3, "y") })),

  s("hlm-cross", fmt([[
data {{
  int<lower=0> N;
  int<lower=1> J;
  int<lower=1> K;
  array[N] int<lower=1, upper=J> group_j;
  array[N] int<lower=1, upper=K> group_k;
  vector[N] {1};
  vector[N] {2};
}}
parameters {{
  real alpha;
  real beta;
  real<lower=0> sigma;
  real<lower=0> sigma_j;
  real<lower=0> sigma_k;
  vector[J] alpha_j_raw;
  vector[K] alpha_k_raw;
}}
transformed parameters {{
  vector[J] alpha_j = sigma_j * alpha_j_raw;
  vector[K] alpha_k = sigma_k * alpha_k_raw;
}}
model {{
  alpha_j_raw ~ std_normal();
  alpha_k_raw ~ std_normal();
  sigma_j ~ exponential(1);
  sigma_k ~ exponential(1);
  sigma ~ exponential(1);
  {2} ~ normal(alpha + alpha_j[group_j] + alpha_k[group_k] + beta * {1}, sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(alpha + alpha_j[group_j] + alpha_k[group_k] + beta * {1}, sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  s("hlm-three", fmt([[
data {{
  int<lower=0> N;
  int<lower=1> J;
  int<lower=1> K;
  array[N] int<lower=1, upper=J> group_j;
  array[N] int<lower=1, upper=K> group_k;
  vector[N] {1};
  vector[N] {2};
}}
parameters {{
  real beta;
  real<lower=0> sigma;
  real mu_alpha;
  real<lower=0> sigma_alpha;
  real mu_gamma;
  real<lower=0> sigma_gamma;
  vector[J] alpha_j_raw;
  vector[K] gamma_k_raw;
}}
transformed parameters {{
  vector[J] alpha_j = mu_alpha + sigma_alpha * alpha_j_raw;
  vector[K] gamma_k = mu_gamma + sigma_gamma * gamma_k_raw;
}}
model {{
  alpha_j_raw ~ std_normal();
  gamma_k_raw ~ std_normal();
  mu_alpha ~ normal(0, 5);
  sigma_alpha ~ exponential(1);
  mu_gamma ~ normal(0, 5);
  sigma_gamma ~ exponential(1);
  sigma ~ exponential(1);
  {2} ~ normal(alpha_j[group_j] + gamma_k[group_k] + beta * {1}, sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(alpha_j[group_j] + gamma_k[group_k] + beta * {1}, sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  -- === Time series ===

  s("ts-ar1", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
}}
parameters {{
  real alpha;
  real<lower=-1, upper=1> phi;
  real<lower=0> sigma;
}}
model {{
  alpha ~ normal(0, 5);
  phi ~ uniform(-1, 1);
  sigma ~ exponential(1);
  {1}[1] ~ normal(alpha, sigma / sqrt(1 - phi^2));
  for (t in 2:N) {{
    {1}[t] ~ normal(alpha + phi * ({1}[t-1] - alpha), sigma);
  }}
}}
generated quantities {{
  vector[N] y_rep;
  y_rep[1] = normal_rng(alpha, sigma / sqrt(1 - phi^2));
  for (t in 2:N) {{
    y_rep[t] = normal_rng(alpha + phi * (y_rep[t-1] - alpha), sigma);
  }}
}}
]], { i(1, "y") })),

  s("ts-ar", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> P;
  vector[N] {1};
}}
parameters {{
  real alpha;
  vector[P] phi;
  real<lower=0> sigma;
}}
model {{
  alpha ~ normal(0, 5);
  phi ~ normal(0, 1);
  sigma ~ exponential(1);
  for (t in (P+1):N) {{
    {1}[t] ~ normal(alpha + {1}[t-P:t-1]' * phi, sigma);
  }}
}}
generated quantities {{
  vector[N] y_rep = {1};
  for (t in (P+1):N) {{
    y_rep[t] = normal_rng(alpha + y_rep[t-P:t-1]' * phi, sigma);
  }}
}}
]], { i(1, "y") })),

  s("ts-arima", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> P;
  int<lower=0> Q;
  vector[N] {1};
}}
transformed data {{
  vector[N-1] dy = diff({1});
}}
parameters {{
  real alpha;
  vector[P] phi;
  vector[Q] theta;
  real<lower=0> sigma;
}}
model {{
  alpha ~ normal(0, 5);
  phi ~ normal(0, 1);
  theta ~ normal(0, 1);
  sigma ~ exponential(1);
  for (t in (max(P,Q)+1):(N-1)) {{
    dy[t] ~ normal(alpha + dy[t-P:t-1]' * phi + sigma * theta' * rep_vector(1, Q), sigma);
  }}
}}
generated quantities {{
  vector[N] y_rep = {1};
  for (t in 2:N) {{
    y_rep[t] = normal_rng(y_rep[t-1], sigma);
  }}
}}
]], { i(1, "y") })),

  s("ts-change", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
}}
parameters {{
  real mu1;
  real mu2;
  real<lower=0> sigma;
  real<lower=1, upper=N> tau;
}}
model {{
  mu1 ~ normal(0, 5);
  mu2 ~ normal(0, 5);
  sigma ~ exponential(1);
  for (t in 1:N) {{
    real mu = t < tau ? mu1 : mu2;
    {1}[t] ~ normal(mu, sigma);
  }}
}}
generated quantities {{
  vector[N] y_rep;
  for (t in 1:N) {{
    real mu = t < tau ? mu1 : mu2;
    y_rep[t] = normal_rng(mu, sigma);
  }}
}}
]], { i(1, "y") })),

  s("ts-latent", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
}}
parameters {{
  vector[N] mu;
  real<lower=0> sigma_obs;
  real<lower=0> sigma_proc;
  real mu0;
}}
model {{
  mu0 ~ normal(0, 5);
  sigma_obs ~ exponential(1);
  sigma_proc ~ exponential(1);
  mu[1] ~ normal(mu0, sigma_proc);
  for (t in 2:N) {{
    mu[t] ~ normal(mu[t-1], sigma_proc);
  }}
  {1} ~ normal(mu, sigma_obs);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(mu, sigma_obs);
}}
]], { i(1, "y") })),

  -- === Mixtures ===

  s("mix-2comp", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
}}
parameters {{
  ordered[2] mu;
  vector<lower=0>[2] sigma;
  real<lower=0, upper=1> lambda;
}}
model {{
  mu ~ normal(0, 10);
  sigma ~ exponential(1);
  lambda ~ beta(1, 1);
  for (n in 1:N) {{
    target += log_mix(lambda,
      normal_lpdf({1}[n] | mu[1], sigma[1]),
      normal_lpdf({1}[n] | mu[2], sigma[2]));
  }}
}}
generated quantities {{
  array[N] int y_rep;
  for (n in 1:N) {{
    y_rep[n] = bernoulli_rng(lambda)
      ? normal_rng(mu[1], sigma[1])
      : normal_rng(mu[2], sigma[2]);
  }}
}}
]], { i(1, "y") })),

  s("mix-kcomp", fmt([[
data {{
  int<lower=1> K;
  int<lower=0> N;
  vector[N] {1};
}}
parameters {{
  ordered[K] mu;
  vector<lower=0>[K] sigma;
  simplex[K] theta;
}}
transformed parameters {{
  vector[K] log_theta = log(theta);
}}
model {{
  mu ~ normal(0, 10);
  sigma ~ exponential(1);
  for (n in 1:N) {{
    vector[K] lps = log_theta;
    for (k in 1:K) {{
      lps[k] += normal_lpdf({1}[n] | mu[k], sigma[k]);
    }}
    target += log_sum_exp(lps);
  }}
}}
generated quantities {{
  array[N] int y_rep;
  for (n in 1:N) {{
    int k = categorical_rng(theta);
    y_rep[n] = normal_rng(mu[k], sigma[k]);
  }}
}}
]], { i(1, "y") })),

  s("mix-zip", fmt([[
data {{
  int<lower=0> N;
  array[N] int<lower=0> {1};
}}
transformed data {{
  int N_zero = 0;
  int N_nonzero = 0;
  for (n in 1:N) {{
    if ({1}[n] == 0) N_zero += 1;
  }}
  N_nonzero = N - N_zero;
}}
parameters {{
  real<lower=0, upper=1> theta;
  real<lower=0> lambda;
}}
model {{
  theta ~ beta(1, 1);
  lambda ~ gamma(2, 1);
  for (n in 1:N) {{
    if ({1}[n] == 0) {{
      target += log_sum_exp(log(theta),
        log1m(theta) + poisson_lpmf(0 | lambda));
    }} else {{
      target += log1m(theta) + poisson_lpmf({1}[n] | lambda);
    }}
  }}
}}
generated quantities {{
  array[N] int y_rep;
  for (n in 1:N) {{
    y_rep[n] = bernoulli_rng(theta)
      ? 0 : poisson_rng(lambda);
  }}
}}
]], { i(1, "y") })),

  s("mix-zinb", fmt([[
data {{
  int<lower=0> N;
  array[N] int<lower=0> {1};
}}
parameters {{
  real<lower=0, upper=1> theta;
  real<lower=0> mu;
  real<lower=0> phi;
}}
model {{
  theta ~ beta(1, 1);
  mu ~ gamma(2, 1);
  phi ~ exponential(1);
  for (n in 1:N) {{
    if ({1}[n] == 0) {{
      target += log_sum_exp(log(theta),
        log1m(theta) + neg_binomial_2_lpmf(0 | mu, phi));
    }} else {{
      target += log1m(theta) + neg_binomial_2_lpmf({1}[n] | mu, phi);
    }}
  }}
}}
generated quantities {{
  array[N] int y_rep;
  for (n in 1:N) {{
    y_rep[n] = bernoulli_rng(theta)
      ? 0 : neg_binomial_2_rng(mu, phi);
  }}
}}
]], { i(1, "y") })),

  s("mix-hurdle", fmt([[
data {{
  int<lower=0> N;
  array[N] int<lower=0> {1};
}}
transformed data {{
  int N0 = 0;
  for (n in 1:N) if ({1}[n] == 0) N0 += 1;
  int N_gt0 = N - N0;
}}
parameters {{
  real<lower=0, upper=1> theta;
  real<lower=0> lambda;
}}
model {{
  theta ~ beta(1, 1);
  lambda ~ gamma(2, 1);
  N0 ~ binomial(N, theta);
  for (n in 1:N) if ({1}[n] > 0) {{
    target += poisson_lpmf({1}[n] | lambda)
              - log1m_exp(-lambda);
  }}
}}
generated quantities {{
  array[N] int y_rep;
  for (n in 1:N) {{
    if (bernoulli_rng(theta)) {{
      y_rep[n] = 0;
    }} else {{
      y_rep[n] = poisson_rng(lambda);
      while (y_rep[n] == 0) y_rep[n] = poisson_rng(lambda);
    }}
  }}
}}
]], { i(1, "y") })),

  -- === Censoring / truncation ===

  s("cens-lower", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  real<lower=0> {2};
}}
parameters {{
  real mu;
  real<lower=0> sigma;
}}
model {{
  mu ~ normal(0, 5);
  sigma ~ exponential(1);
  for (n in 1:N) {{
    if ({1}[n] >= {2}) {{
      target += normal_lccdf({1}[n] | mu, sigma);
    }} else {{
      {1}[n] ~ normal(mu, sigma);
    }}
  }}
}}
generated quantities {{
  vector[N] y_rep;
  for (n in 1:N) {{
    y_rep[n] = normal_rng(mu, sigma);
    if (y_rep[n] >= {2}) y_rep[n] = {2};
  }}
}}
]], { i(1, "y"), i(2, "U") })),

  s("cens-upper", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  real<lower=0> {2};
}}
parameters {{
  real mu;
  real<lower=0> sigma;
}}
model {{
  mu ~ normal(0, 5);
  sigma ~ exponential(1);
  for (n in 1:N) {{
    if ({1}[n] <= {2}) {{
      target += normal_lcdf({1}[n] | mu, sigma);
    }} else {{
      {1}[n] ~ normal(mu, sigma);
    }}
  }}
}}
generated quantities {{
  vector[N] y_rep = normal_rng(mu, sigma);
}}
]], { i(1, "y"), i(2, "L") })),

  s("cens-interval", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  vector[N] {2};
  vector[N] {3};
}}
parameters {{
  real mu;
  real<lower=0> sigma;
}}
model {{
  mu ~ normal(0, 5);
  sigma ~ exponential(1);
  for (n in 1:N) {{
    if ({1}[n] < {2}[n]) {{
      target += normal_lcdf({1}[n] | mu, sigma);
    }} else if ({1}[n] > {3}[n]) {{
      target += normal_lccdf({1}[n] | mu, sigma);
    }} else {{
      {1}[n] ~ normal(mu, sigma);
    }}
  }}
}}
generated quantities {{
  vector[N] y_rep = normal_rng(mu, sigma);
}}
]], { i(1, "y"), i(2, "lo"), i(3, "hi") })),

  -- === Missing data ===

  s("miss-normal", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  int<lower=0> N_miss;
  array[N_miss] int<lower=1, upper=N> miss_idx;
}}
parameters {{
  real mu;
  real<lower=0> sigma;
  vector[N_miss] {2};
}}
transformed parameters {{
  vector[N] y_obs;
  y_obs = {1};
  for (n in 1:N_miss) {{
    int idx = miss_idx[n];
    y_obs[idx] = {2}[n];
  }}
}}
model {{
  mu ~ normal(0, 5);
  sigma ~ exponential(1);
  y_obs ~ normal(mu, sigma);
}}
generated quantities {{
  vector[N] y_rep = normal_rng(mu, sigma);
}}
]], { i(1, "y"), i(2, "y_miss") })),

  s("miss-multi", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> P;
  matrix[N, P] {1};
  array[N] int<lower=0, upper=P> miss_count;
}}
transformed data {{
  int N_miss = sum(miss_count);
}}
parameters {{
  vector[P] mu;
  vector<lower=0>[P] sigma;
  corr_matrix[P] Omega;
  vector[N_miss] y_miss;
}}
transformed parameters {{
  vector[P] y_imp[N];
  {{
    int pos = 1;
    for (n in 1:N) {{
      for (p in 1:P) {{
        if (is_nan({1}[n, p])) {{
          y_imp[n][p] = y_miss[pos]; pos += 1;
        }} else {{
          y_imp[n][p] = {1}[n, p];
        }}
      }}
    }}
  }}
}}
model {{
  mu ~ normal(0, 5);
  sigma ~ exponential(1);
  Omega ~ lkj_corr(2);
  for (n in 1:N) {{
    y_imp[n] ~ multi_normal(mu, quad_form_diag(Omega, sigma));
  }}
}}
]], { i(1, "Y") })),

  s("miss-mi", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> N_obs;
  array[N_obs] int obs_idx;
  vector[N_obs] {1};
}}
parameters {{
  real mu;
  real<lower=0> sigma;
  vector[N - N_obs] {2};
}}
model {{
  mu ~ normal(0, 5);
  sigma ~ exponential(1);
  {1} ~ normal(mu, sigma);
  {2} ~ normal(mu, sigma);
}}
generated quantities {{
  vector[N] y_imp;
  y_imp[obs_idx] = {1};
  y_imp[sort_indices_asc(obs_idx)] = {2};
  vector[N] y_rep = normal_rng(mu, sigma);
}}
]], { i(1, "y_obs"), i(2, "y_mis") })),

  -- === Gaussian processes ===

  s("gp-reg", fmt([[
data {{
  int<lower=1> N;
  vector[N] {1};
  vector[N] {2};
}}
transformed data {{
  real delta = 1e-9;
}}
parameters {{
  real<lower=0> rho;
  real<lower=0> alpha;
  real<lower=0> sigma;
  vector[N] eta;
}}
model {{
  matrix[N, N] L_K;
  matrix[N, N] K = gp_exp_quad_cov({1}, alpha, rho);
  for (n in 1:N) {{
    K[n, n] += delta;
  }}
  L_K = cholesky_decompose(K);
  rho ~ inv_gamma(5, 5);
  alpha ~ normal(0, 2);
  sigma ~ exponential(1);
  {2} ~ normal(0, sigma);
  eta ~ multi_normal_cholesky(rep_vector(0, N), L_K);
}}
generated quantities {{
  vector[N] f;
  matrix[N, N] L_K;
  matrix[N, N] K = gp_exp_quad_cov({1}, alpha, rho);
  for (n in 1:N) K[n, n] += delta;
  L_K = cholesky_decompose(K);
  f = L_K * eta;
  vector[N] y_rep = normal_rng(f, sigma);
}}
]], { i(1, "x"), i(2, "y") })),

  s("gp-cov-exp", fmt([[
data {{
  int<lower=1> N;
  vector[N] {1};
}}
transformed data {{
  real delta = 1e-9;
}}
parameters {{
  real<lower=0> rho;
  real<lower=0> alpha;
  real<lower=0> sigma;
}}
transformed parameters {{
  matrix[N, N] K = gp_exp_quad_cov({1}, alpha, rho);
  matrix[N, N] L_K;
  for (n in 1:N) {{
    K[n, n] += delta;
  }}
  L_K = cholesky_decompose(K);
}}
model {{
  rho ~ inv_gamma(5, 5);
  alpha ~ normal(0, 2);
  sigma ~ exponential(1);
}}
]], { i(1, "x") })),

  s("gp-approx", fmt([[
data {{
  int<lower=1> N;
  int<lower=1> M;
  vector[N] {1};
  vector[M] x_pred;
  vector[N] {2};
}}
transformed data {{
  real delta = 1e-9;
  matrix[N, M] K_uf;
  matrix[M, M] K_f = gp_exp_quad_cov(x_pred, {3}, {4});
  matrix[N, M] K_uf_lin;
  for (n in 1:N) {{
    for (m in 1:M) {{
      K_uf[n, m] = {3}^2 * exp(-0.5 * ((({1}[n] - x_pred[m])/{4})^2));
    }}
  }}
  for (m in 1:M) K_f[m, m] += delta;
  matrix[M, M] L_f = cholesky_decompose(K_f);
  K_uf_lin = mdivide_right_tri_low(K_uf, L_f);
}}
parameters {{
  real<lower=0> sigma;
  vector[M] eta;
  real<lower=0> {3};
  real<lower=0> {4};
}}
model {{
  vector[N] f = K_uf_lin * eta;
  {3} ~ normal(0, 2);
  {4} ~ inv_gamma(5, 5);
  sigma ~ exponential(1);
  eta ~ std_normal();
  {2} ~ normal(f, sigma);
}}
]], { i(1, "x"), i(2, "y"), i(3, "alpha"), i(4, "rho") })),

  -- === Survival ===

  s("surv-exp", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  array[N] int<lower=0, upper=1> {2};
}}
parameters {{
  real beta;
}}
model {{
  beta ~ normal(0, 5);
  for (n in 1:N) {{
    if ({2}[n] == 1) {{
      target += exponential_lpdf({1}[n] | exp(beta));
    }} else {{
      target += exponential_lccdf({1}[n] | exp(beta));
    }}
  }}
}}
generated quantities {{
  array[N] real t_rep;
  for (n in 1:N) {{
    t_rep[n] = exponential_rng(exp(beta));
  }}
}}
]], { i(1, "t"), i(2, "fail") })),

  s("surv-weib", fmt([[
data {{
  int<lower=0> N;
  vector[N] {1};
  array[N] int<lower=0, upper=1> {2};
}}
parameters {{
  real alpha;
  real<lower=0> sigma;
}}
model {{
  alpha ~ normal(0, 5);
  sigma ~ exponential(1);
  for (n in 1:N) {{
    if ({2}[n] == 1) {{
      target += weibull_lpdf({1}[n] | sigma, exp(alpha));
    }} else {{
      target += weibull_lccdf({1}[n] | sigma, exp(alpha));
    }}
  }}
}}
generated quantities {{
  array[N] real t_rep;
  for (n in 1:N) {{
    t_rep[n] = weibull_rng(sigma, exp(alpha));
  }}
}}
]], { i(1, "t"), i(2, "fail") })),

  s("surv-cox", fmt([[
data {{
  int<lower=0> N;
  int<lower=0> K;
  matrix[N, K] {1};
  vector[N] {2};
  array[N] int<lower=0, upper=1> {3};
}}
parameters {{
  vector[K] beta;
  vector[N] log_h0;
}}
model {{
  beta ~ normal(0, 2.5);
  log_h0 ~ normal(0, 5);
  for (n in 1:N) {{
    real log_haz = log_h0[n] + {1}[n] * beta;
    if ({3}[n] == 1) {{
      target += log_haz + exponential_lpdf({2}[n] | exp(log_haz));
    }} else {{
      target += exponential_lccdf({2}[n] | exp(log_haz));
    }}
  }}
}}
]], { i(1, "X"), i(2, "t"), i(3, "fail") })),

  -- === User functions ===

  s("func-def", fmt([[
functions {{
  real {1}({2}) {{
    return {3};
  }}
}}
]], { i(1, "my_func"), i(2, "real x"), i(3, "x^2") })),

  s("func-logpmf", fmt([[
functions {{
  real {1}_lpmf(array[] int y, {2}) {{
    int N = size(y);
    real lp = 0.0;
    for (n in 1:N) {{
      lp += {3};
    }}
    return lp;
  }}
}}
]], { i(1, "my_dist"), i(2, "real theta"), i(3, "bernoulli_lpmf(y[n] | theta)") })),

  s("func-logpdf", fmt([[
functions {{
  real {1}_lpdf(array[] real y, {2}) {{
    int N = size(y);
    real lp = 0.0;
    for (n in 1:N) {{
      lp += {3};
    }}
    return lp;
  }}
}}
]], { i(1, "my_dist"), i(2, "real mu, real sigma"), i(3, "normal_lpdf(y[n] | mu, sigma)") })),

  s("func-rng", fmt([[
functions {{
  real {1}_rng({2}) {{
    {3}
  }}
}}
]], { i(1, "my_dist"), i(2, "real mu, real sigma"), i(3, "return normal_rng(mu, sigma);") })),

  -- === Reparameterization ===

  s("reparam-cent", fmt([[
parameters {{
  real {1};
  real<lower=0> {2};
  vector[{4}] {3};
}}
model {{
  {3} ~ normal({1}, {2});
}}
]], { i(1, "mu"), i(2, "sigma"), i(3, "alpha_j"), i(4, "J") })),

  s("reparam-noncent", fmt([[
parameters {{
  real {1};
  real<lower=0> {2};
  vector[{4}] {3}_raw;
}}
transformed parameters {{
  vector[{4}] {3} = {1} + {2} * {3}_raw;
}}
model {{
  {3}_raw ~ std_normal();
}}
]], { i(1, "mu"), i(2, "sigma"), i(3, "alpha_j"), i(4, "J") })),

  s("reparam-qr", fmt([[
transformed data {{
  matrix[N, K] Q_ast = qr_thin_Q({1}) * sqrt(N - 1);
  matrix[K, K] R_ast = qr_thin_R({1}) / sqrt(N - 1);
  matrix[K, K] R_ast_inverse = inverse(R_ast);
}}
parameters {{
  real alpha;
  vector[K] theta;
  real<lower=0> sigma;
}}
model {{
  {2} ~ normal(Q_ast * theta + alpha, sigma);
}}
generated quantities {{
  vector[K] beta = R_ast_inverse * theta;
}}
]], { i(1, "X"), i(2, "y") })),

  s("reparam-chol", fmt([[
parameters {{
  vector[K] mu;
  vector<lower=0>[K] sigma;
  cholesky_factor_corr[K] L_Omega;
  matrix[K, N] z;
}}
transformed parameters {{
  matrix[N, K] y_std = z';
  matrix[N, K] {1} = rep_matrix(mu', N) + y_std * diag_pre_multiply(sigma, L_Omega)';
}}
model {{
  mu ~ normal(0, 5);
  sigma ~ exponential(1);
  L_Omega ~ lkj_corr_cholesky(2);
  to_vector(z) ~ std_normal();
}}
]], { i(1, "y") })),

  -- === Generated quantities ===

  s("genq-ppred-norm", fmt([[
generated quantities {{
  vector[N] {1} = normal_rng({2}, {3});
}}
]], { i(1, "y_rep"), i(2, "mu"), i(3, "sigma") })),

  s("genq-ppred-bern", fmt([[
generated quantities {{
  array[N] int {1} = bernoulli_rng({2});
}}
]], { i(1, "y_rep"), i(2, "theta") })),

  s("genq-ppred-pois", fmt([[
generated quantities {{
  array[N] int {1} = poisson_rng({2});
}}
]], { i(1, "y_rep"), i(2, "lambda") })),

  s("genq-ppred-count", fmt([[
generated quantities {{
  array[N] int {1} = neg_binomial_2_rng({2}, {3});
}}
]], { i(1, "y_rep"), i(2, "mu"), i(3, "phi") })),

  s("genq-lpd", fmt([[
generated quantities {{
  vector[N] log_lik;
  for (n in 1:N) {{
    log_lik[n] = {1};
  }}
}}
]], { i(1, "normal_lpdf(y[n] | mu, sigma)") })),

  s("genq-resid", fmt([[
generated quantities {{
  vector[N] resid = {1} - {2};
  vector[N] std_resid = resid / {3};
}}
]], { i(1, "y"), i(2, "mu"), i(3, "sigma") })),

  -- === Diagnostics ===

  s("diag-rhat", fmt([[
// Run with: bayesplot::mcmc_rhat(rhat(fit))
// Target: R-hat < 1.01 for all parameters
{1}
]], { i(0) })),

  s("diag-divergent", fmt([[
// Check divergent transitions:
// bayesplot::mcmc_parcoord(fit, np = nuts_params(fit))
// Divergent transitions suggest posterior geometry issues
{1}
]], { i(0) })),

  s("diag-loo", fmt([[
// Use loo package for approximate LOO-CV:
// library(loo)
// log_lik <- extract_log_lik(fit, parameter_name = "log_lik")
// r_eff <- relative_eff(exp(log_lik))
// loo(log_lik, r_eff = r_eff)
{1}
]], { i(0) })),

  -- === Meta-analysis ===

  s("meta-fixed", fmt([[
data {{
  int<lower=0> K;
  vector[K] {1};
  vector<lower=0>[K] {2};
}}
parameters {{
  real mu;
}}
model {{
  mu ~ normal(0, 5);
  {1} ~ normal(mu, {2});
}}
generated quantities {{
  vector[K] y_rep = normal_rng(mu, {2});
}}
]], { i(1, "y"), i(2, "se") })),

  s("meta-random", fmt([[
data {{
  int<lower=0> K;
  vector[K] {1};
  vector<lower=0>[K] {2};
}}
parameters {{
  real mu;
  real<lower=0> tau;
  vector[K] eta;
}}
transformed parameters {{
  vector[K] theta = mu + tau * eta;
}}
model {{
  mu ~ normal(0, 5);
  tau ~ exponential(1);
  eta ~ std_normal();
  {1} ~ normal(theta, {2});
}}
generated quantities {{
  vector[K] y_rep = normal_rng(theta, {2});
  real y_new = normal_rng(mu, sqrt(tau^2 + mean({2}^2)));
}}
]], { i(1, "y"), i(2, "se") })),

  s("meta-network", fmt([[
data {{
  int<lower=0> K;
  int<lower=0> T;
  array[K] int<lower=1, upper=T> t1;
  array[K] int<lower=1, upper=T> t2;
  vector[K] {1};
  vector<lower=0>[K] {2};
}}
parameters {{
  vector[T] mu;
  real<lower=0> tau;
}}
transformed parameters {{
  vector[K] delta;
  for (k in 1:K) {{
    int i = t1[k];
    int j = t2[k];
    delta[k] = mu[i] - mu[j];
  }}
}}
model {{
  mu ~ normal(0, 5);
  tau ~ exponential(1);
  {1} ~ normal(delta, sqrt({2} .^ 2 + tau^2));
}}
]], { i(1, "y"), i(2, "se") })),

  -- === Aliases (backward compat from stats.lua) ===

  s("model",  fmt("model {{\n  {1}\n}}", { i(0) })),
  s("data",   fmt("data {{\n  {1}\n}}", { i(0) })),
  s("params", fmt("parameters {{\n  {1}\n}}", { i(0) })),
  s("genq",   fmt("generated quantities {{\n  {1}\n}}", { i(0) })),
})
