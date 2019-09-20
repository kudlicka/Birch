cpp{{
#include <random>

thread_local static std::mt19937_64 rng;
}}

/**
 * Seed the pseudorandom number generator.
 *
 * - seed: Seed value.
 */
function seed(s:Integer) {
  cpp{{
  #ifdef _OPENMP
  #pragma omp parallel num_threads(libbirch::nthreads)
  {
    rng.seed(s + libbirch::tid);
  }
  #else
  rng.seed(s);
  #endif
  }}
}

/**
 * Seed the pseudorandom number generator with entropy.
 */
function seed() {
  cpp{{
  std::random_device rd;
  #ifdef _OPENMP
  #pragma omp parallel num_threads(libbirch::nthreads)
  {
    #pragma omp critical
    rng.seed(rd());
  }
  #else
  rng.seed(rd());
  #endif
  }}
}

/**
 * Simulate a Bernoulli distribution.
 *
 * - ρ: Probability of a true result.
 */
function simulate_bernoulli(ρ:Real) -> Boolean {
  assert 0.0 <= ρ && ρ <= 1.0;
  cpp{{
  return std::bernoulli_distribution(ρ)(rng);
  }}
}

/**
 * Simulate a delta distribution.
 *
 * - μ: Location.
 */
function simulate_delta(μ:Integer) -> Integer {
  return μ;
}

/**
 * Simulate a binomial distribution.
 *
 * - n: Number of trials.
 * - ρ: Probability of a true result.
 */
function simulate_binomial(n:Integer, ρ:Real) -> Integer {
  assert 0 <= n;
  assert 0.0 <= ρ && ρ <= 1.0;
  cpp{{
  return std::binomial_distribution<bi::type::Integer>(n, ρ)(rng);
  }}
}

/**
 * Simulate a negative binomial distribution.
 *
 * - k: Number of successes before the experiment is stopped.
 * - ρ: Probability of success.
 *
 * Returns the number of failures.
 */
function simulate_negative_binomial(k:Integer, ρ:Real) -> Integer {
  assert 0 < k;
  assert 0.0 <= ρ && ρ <= 1.0;
  cpp{{
  return std::negative_binomial_distribution<bi::type::Integer>(k, ρ)(rng);
  }}
}

/**
 * Simulate a Poisson distribution.
 *
 * - λ: Rate.
 */
function simulate_poisson(λ:Real) -> Integer {
  assert 0.0 <= λ;
  if (λ > 0.0) {
    cpp{{
    return std::poisson_distribution<bi::type::Integer>(λ)(rng);
    }}
  } else {
    return 0;
  }
}

/**
 * Simulate a categorical distribution.
 *
 * - ρ: Category probabilities. These should sum to one.
 */
function simulate_categorical(ρ:Real[_]) -> Integer {
  return simulate_categorical(ρ, 1.0);
}

/**
 * Simulate a categorical distribution.
 *
 * - ρ: Unnormalized category probabilities.
 * - Z: Sum of the unnormalized category probabilities.
 */
function simulate_categorical(ρ:Real[_], Z:Real) -> Integer {
  assert length(ρ) > 0;
  assert abs(sum(ρ) - Z) < 1.0e-6;

  u:Real <- simulate_uniform(0.0, Z);
  x:Integer <- 1;
  P:Real <- ρ[1];
  while (P < u) {
    assert x <= length(ρ);
    x <- x + 1;
    assert 0.0 <= ρ[x];
    P <- P + ρ[x];
    assert P < Z + 1.0e-6;
  }
  return x;
}

/**
 * Simulate a multinomial distribution.
 *
 * - n: Number of trials.
 * - ρ: Category probabilities. These should sum to one.
 *
 * This uses an $\mathcal{O}(N)$ implementation based on:
 *
 * Bentley, J. L. and J. B. Saxe (1979). Generating sorted lists of random
 * numbers. Technical Report 2450, Carnegie Mellon University, Computer
 * Science Department.
 */
function simulate_multinomial(n:Integer, ρ:Real[_]) -> Integer[_] {
  return simulate_multinomial(n, ρ, 1.0);
}

/**
 * Simulate a compound-gamma distribution.
 *
 * - k: Shape.
 * - α: Shape.
 * - β: Scale.
 *
 */
 function simulate_compound_gamma(k:Real, α:Real, β:Real) -> Real {
    return simulate_gamma(k, simulate_inverse_gamma(α, β));
 }

/**
 * Simulate a multinomial distribution.
 *
 * - n: Number of trials.
 * - ρ: Unnormalized category probabilities.
 * - Z: Sum of the unnormalized category probabilities.
 *
 * This uses an $\mathcal{O}(N)$ implementation based on:
 *
 * Bentley, J. L. and J. B. Saxe (1979). Generating sorted lists of random
 * numbers. Technical Report 2450, Carnegie Mellon University, Computer
 * Science Department.
 */
function simulate_multinomial(n:Integer, ρ:Real[_], Z:Real) -> Integer[_] {
  assert length(ρ) > 0;
  assert abs(sum(ρ) - Z) < 1.0e-6;

  D:Integer <- length(ρ);
  R:Real <- ρ[D];
  lnMax:Real <- 0.0;
  j:Integer <- D;
  i:Integer <- n;
  u:Real;
  x:Integer[D];
    
  while i > 0 {
    u <- simulate_uniform(0.0, 1.0);
    lnMax <- lnMax + log(u)/i;
    u <- Z*exp(lnMax);
    while u < Z - R {
      j <- j - 1;
      R <- R + ρ[j];
    }
    x[j] <- x[j] + 1;
    i <- i - 1;
  }
  while j > 1 {
    j <- j - 1;
    x[j] <- 0;
  }
  return x;
}

/**
 * Simulate a Dirichlet distribution.
 *
 * - α: Concentrations.
 */
function simulate_dirichlet(α:Real[_]) -> Real[_] {
  D:Integer <- length(α);
  x:Real[D];
  z:Real <- 0.0;

  for (i:Integer in 1..D) {
    x[i] <- simulate_gamma(α[i], 1.0);
    z <- z + x[i];
  }
  z <- 1.0/z;
  for (i:Integer in 1..D) {
    x[i] <- z*x[i];
  }
  return x;
}

/**
 * Simulate a Dirichlet distribution.
 *
 * - α: Concentration.
 * - D: Number of dimensions.
 */
function simulate_dirichlet(α:Real, D:Integer) -> Real[_] {
  assert D >= 0;
  x:Real[D];
  z:Real <- 0.0;

  for (i:Integer in 1..D) {
    x[i] <- simulate_gamma(α, 1.0);
    z <- z + x[i];
  }
  z <- 1.0/z;
  for (i:Integer in 1..D) {
    x[i] <- z*x[i];
  }
  return x;
}

/**
 * Simulate a uniform distribution.
 *
 * - l: Lower bound of interval.
 * - u: Upper bound of interval.
 */
function simulate_uniform(l:Real, u:Real) -> Real {
  assert l <= u;
  cpp{{
  return std::uniform_real_distribution<bi::type::Real>(l, u)(rng);
  }}
}

/**
 * Simulate a uniform distribution on an integer range.
 *
 * - l: Lower bound of range.
 * - u: Upper bound of range.
 */
function simulate_uniform_int(l:Integer, u:Integer) -> Integer {
  assert l <= u;
  cpp{{
  return std::uniform_int_distribution<bi::type::Integer>(l, u)(rng);
  }}
}

/**
 * Simulate a uniform distribution on unit vectors.
 *
 * - D: Number of dimensions.
 */
function simulate_uniform_unit_vector(D:Integer) -> Real[_] {
  u:Real[D];
  for d:Integer in 1..D {
    u[d] <- simulate_gaussian(0.0, 1.0);
  }
  return u/dot(u);
}

/**
 * Simulate an exponential distribution.
 *
 * - λ: Rate.
 */
function simulate_exponential(λ:Real) -> Real {
  assert 0.0 < λ;
  cpp{{
  return std::exponential_distribution<bi::type::Real>(λ)(rng);
  }}
}

/**
 * Simulate an Weibull distribution.
 *
 * - k: Shape.
 * - λ: Scale.
 */
function simulate_weibull(k:Real, λ:Real) -> Real {
  assert 0.0 < k;
  assert 0.0 < λ;
  cpp{{
  return std::weibull_distribution<bi::type::Real>(k, λ)(rng);
  }}
}

/**
 * Simulate a Gaussian distribution.
 *
 * - μ: Mean.
 * - σ2: Variance.
 */
function simulate_gaussian(μ:Real, σ2:Real) -> Real {
  assert 0.0 <= σ2;
  if (σ2 == 0.0) {
    return μ;
  } else {
    cpp{{
    return std::normal_distribution<bi::type::Real>(μ, std::sqrt(σ2))(rng);
    }}
  }
}

/**
 * Simulate a Student's $t$-distribution.
 *
 * - ν: Degrees of freedom.
 */
function simulate_student_t(ν:Real) -> Real {
  assert 0.0 < ν;
  cpp{{
  return std::student_t_distribution<bi::type::Real>(ν)(rng);
  }}
}

/**
 * Simulate a Student's $t$-distribution with location and scale.
 *
 * - ν: Degrees of freedom.
 * - μ: Location.
 * - σ2: Squared scale.
 */
function simulate_student_t(ν:Real, μ:Real, σ2:Real) -> Real {
  assert 0.0 < ν;
  if (σ2 == 0.0) {
    return μ;
  } else {
    return μ + sqrt(σ2)*simulate_student_t(ν);
  }
}

/**
 * Simulate a beta distribution.
 *
 * - α: Shape.
 * - β: Shape.
 */
function simulate_beta(α:Real, β:Real) -> Real {
  assert 0.0 < α;
  assert 0.0 < β;
  
  u:Real <- simulate_gamma(α, 1.0);
  v:Real <- simulate_gamma(β, 1.0);
  
  return u/(u + v);
}

/**
 * Simulate $\chi^2$ distribution.
 *
 * - ν: Degrees of freedom.
 */
function simulate_chi_squared(ν:Real) -> Real {
  assert 0.0 < ν;
  cpp{{
  return std::chi_squared_distribution<bi::type::Real>(ν)(rng);
  }}
}

/**
 * Simulate a gamma distribution.
 *
 * - k: Shape.
 * - θ: Scale.
 */
function simulate_gamma(k:Real, θ:Real) -> Real {
  assert 0.0 < k;
  assert 0.0 < θ;
  cpp{{
  return std::gamma_distribution<bi::type::Real>(k, θ)(rng);
  }}
}

/**
 * Simulate a Wishart distribution.
 *
 * - Ψ: Scale.
 * - ν: Degrees of freedeom.
 */
function simulate_wishart(Ψ:Real[_,_], ν:Real) -> Real[_,_] {
  assert rows(Ψ) == columns(Ψ);
  assert ν > rows(Ψ) - 1;
  auto p <- rows(Ψ);
  A:Real[p,p];
  
  for auto i in 1..p {
    for auto j in 1..p {
      if j == i {
        /* on diagonal */
        A[i,j] <- simulate_chi_squared(ν - i + 1);
      } else if j < i {
        /* in lower triangle */
        A[i,j] <- simulate_gaussian(0.0, 1.0);
      } else {
        /* in upper triangle */
        A[i,j] <- 0.0;
      }
    }
  }
  auto L <- cholesky(Ψ)*A;
  return L*transpose(L);
}

/**
 * Simulate an inverse-gamma distribution.
 *
 * - α: Shape.
 * - β: Scale.
 */
function simulate_inverse_gamma(α:Real, β:Real) -> Real {
  return 1.0/simulate_gamma(α, 1.0/β);
}

/**
 * Simulate an inverse-Wishart distribution.
 *
 * - Ψ: Scale.
 * - ν: Degrees of freedeom.
 */
function simulate_inverse_wishart(Ψ:Real[_,_], ν:Real) -> Real[_,_] {
  return inv(llt(simulate_wishart(inv(llt(Ψ)), ν)));
}

/**
 * Simulate a normal inverse-gamma distribution.
 *
 * - μ: Mean.
 * - a2: Variance.
 * - α: Shape of inverse-gamma on scale.
 * - β: Scale of inverse-gamma on scale.
 */
function simulate_normal_inverse_gamma(μ:Real, a2:Real, α:Real,
    β:Real) -> Real {
  return simulate_student_t(2.0*α, μ, a2*β/α);
}

/**
 * Simulate a beta-bernoulli distribution.
 *
 * - α: Shape.
 * - β: Shape.
 */
function simulate_beta_bernoulli(α:Real, β:Real) -> Boolean {
  assert 0.0 < α;
  assert 0.0 < β;
  
  return simulate_bernoulli(simulate_beta(α, β));
}

/**
 * Simulate a beta-binomial distribution.
 *
 * - n: Number of trials.
 * - α: Shape.
 * - β: Shape.
 */
function simulate_beta_binomial(n:Integer, α:Real, β:Real) -> Integer {
  assert 0 <= n;
  assert 0.0 < α;
  assert 0.0 < β;
  
  return simulate_binomial(n, simulate_beta(α, β));
}

/**
 * Simulate a beta-negative-binomial distribution.
 *
 * - k: Number of successes.
 * - α: Shape.
 * - β: Shape.
 */
function simulate_beta_negative_binomial(k:Integer, α:Real, β:Real) -> Integer {
  assert 0.0 < α;
  assert 0.0 < β;
  assert 0 < k;

  return simulate_negative_binomial(k, simulate_beta(α, β));
}


/**
 * Simulate a gamma-Poisson distribution.
 *
 * - k: Shape.
 * - θ: Scale.
 */
function simulate_gamma_poisson(k:Real, θ:Real) -> Integer {
  assert 0.0 < k;
  assert 0.0 < θ;
  assert k == floor(k);
  
  return simulate_negative_binomial(Integer(k), 1.0/(θ + 1.0));
}

/**
 * Simulate a Lomax distribution.
 *
 * - λ: Scale.
 * - α: Shape.
 */
function simulate_lomax(λ:Real, α:Real) -> Real {
  assert 0.0 < λ;
  assert 0.0 < α;

  u:Real <- simulate_uniform(0.0, 1.0);
  return λ*(pow(u, -1.0/α)-1.0);
}

/**
 * Simulate a Dirichlet-categorical distribution.
 *
 * - α: Concentrations.
 */
function simulate_dirichlet_categorical(α:Real[_]) -> Integer {
  return simulate_categorical(simulate_dirichlet(α));
}

/**
 * Simulate a Dirichlet-multinomial distribution.
 *
 * - n: Number of trials.
 * - α: Concentrations.
 */
function simulate_dirichlet_multinomial(n:Integer, α:Real[_]) ->
    Integer[_] {
  return simulate_multinomial(n, simulate_dirichlet(α));
}

/**
 * Simulate a categorical distribution with Chinese restaurant process
 * prior.
 *
 * - α: Concentration.
 * - θ: Discount.
 * - n: Enumerated items.
 * - N: Total number of items.
 */
function simulate_crp_categorical(α:Real, θ:Real, n:Integer[_],
    N:Integer) -> Integer {
  assert N >= 0;
  assert sum(n) == N;

  k:Integer <- 0;
  K:Integer <- length(n);
  if (N == 0) {
    /* first component */
    k <- 1;
  } else {
    u:Real <- simulate_uniform(0.0, N + θ);
    U:Real <- K*α + θ;
    if (u < U) {
      /* new component */
      k <- K + 1;
    } else {
      /* existing component */
      while (k < K && u > U) {
        k <- k + 1;
        U <- U + n[k] - α;
      }
    }
  }
  return k;
}

/**
 * Simulate a Gaussian distribution with an inverse-gamma prior over
 * the variance.
 *
 * - μ: Mean.
 * - α: Shape of the inverse-gamma.
 * - β: Scale of the inverse-gamma.
 */
function simulate_inverse_gamma_gaussian(μ:Real, α:Real, β:Real) -> Real {
  return simulate_student_t(2.0*α, μ, β/α);
}

/**
 * Simulate a Gaussian distribution with a normal inverse-gamma prior.
 *
 * - μ: Mean.
 * - a2: Variance.
 * - α: Shape of the inverse-gamma.
 * - β: Scale of the inverse-gamma.
 */
function simulate_normal_inverse_gamma_gaussian(μ:Real, a2:Real,
    α:Real, β:Real) -> Real {
  return simulate_student_t(2.0*α, μ, (β/α)*(1.0 + a2));
}

/**
 * Simulate a Gaussian distribution with a normal inverse-gamma prior.
 *
 * - a: Scale.
 * - μ: Mean.
 * - c: Offset.
 * - a2: Variance.
 * - α: Shape of the inverse-gamma.
 * - β: Scale of the inverse-gamma.
 */
function simulate_linear_normal_inverse_gamma_gaussian(a:Real, μ:Real,
    c:Real, a2:Real, α:Real, β:Real) -> Real {
  return simulate_student_t(2.0*α, a*μ + c, (β/α)*(1.0 + a*a*a2));
}

/**
 * Simulate a multivariate Gaussian distribution.
 *
 * - μ: Mean.
 * - Σ: Covariance.
 */
function simulate_multivariate_gaussian(μ:Real[_], Σ:Real[_,_]) -> Real[_] {
  auto D <- length(μ);
  z:Real[D];
  for auto d in 1..D {
    z[d] <- simulate_gaussian(0.0, 1.0);
  }
  return μ + cholesky(Σ)*z;
}

/**
 * Simulate a multivariate Gaussian distribution with independent and
 * identical variance.
 *
 * - μ: Mean.
 * - σ2: Variance.
 */
function simulate_identical_gaussian(μ:Real[_], σ2:Real) -> Real[_] {
  auto D <- length(μ);
  auto σ <- sqrt(σ2);
  z:Real[D];
  for auto d in 1..D {
    z[d] <- μ[d] + σ*simulate_gaussian(0.0, 1.0);
  }
  return z;
}

/**
 * Simulate a multivariate Gaussian distribution with independent
 * (diagonal) covariance.
 *
 * - μ: Mean.
 * - σ2: Variance.
 */
function simulate_independent_gaussian(μ:Real[_], σ2:Real[_]) -> Real[_] {
  auto D <- length(μ);
  z:Real[D];
  for auto d in 1..D {
    z[d] <- μ[d] + simulate_gaussian(0.0, σ2[d]);
  }
  return z;
}

/**
 * Simulate a multivariate Gaussian distribution with an inverse-gamma prior
 * over a diagonal covariance.
 *
 * - μ: Mean.
 * - α: Shape of the inverse-gamma.
 * - β: Scale of the inverse-gamma.
 */
function simulate_inverse_gamma_multivariate_gaussian(μ:Real[_], α:Real,
    β:Real) -> Real[_] {
  D:Integer <- length(μ);
  z:Real[D];
  a:Real <- sqrt(β/α);
  for (d:Integer in 1..D) {
    z[d] <- μ[d] + a*simulate_student_t(2.0*α);
  }
  return z;
}

/**
 * Simulate a multivariate normal inverse-gamma distribution.
 *
 * - ν: Precision times mean.
 * - Λ: Precision.
 * - α: Shape of inverse-gamma on scale.
 * - β: Scale of inverse-gamma on scale.
 */
function simulate_multivariate_normal_inverse_gamma(ν:Real[_], Λ:LLT,
    α:Real, β:Real) -> Real[_] {
  return simulate_multivariate_student_t(2.0*α, solve(Λ, ν), (β/α)*inv(Λ));
}

/**
 * Simulate a multivariate Gaussian distribution with a multivariate normal
 * inverse-gamma prior.
 *
 * - ν: Precision times mean.
 * - Λ: Precision.
 * - α: Shape of the inverse-gamma.
 * - β: Scale of the inverse-gamma.
 */
function simulate_multivariate_normal_inverse_gamma_multivariate_gaussian(
    ν:Real[_], Λ:LLT, α:Real, β:Real) -> Real[_] {
  return simulate_multivariate_student_t(2.0*α, solve(Λ, ν),
      (β/α)*(identity(rows(Λ)) + inv(Λ)));
}

/**
 * Simulate a Gaussian distribution with a multivariate linear normal
 * inverse-gamma prior.
 *
 * - A: Scale.
 * - ν: Precision times mean.
 * - c: Offset.
 * - Λ: Precision.
 * - α: Shape of the inverse-gamma.
 * - β: Scale of the inverse-gamma.
 */
function simulate_linear_multivariate_normal_inverse_gamma_multivariate_gaussian(
    A:Real[_,_], ν:Real[_], c:Real[_], Λ:LLT, α:Real, β:Real) -> Real[_] {
  return simulate_multivariate_student_t(2.0*α, A*solve(Λ, ν) + c,
      (β/α)*(identity(rows(A)) + A*solve(Λ, transpose(A))));
}

/**
 * Simulate a Gaussian distribution with a multivariate dot normal inverse-gamma
 * prior.
 *
 * - a: Scale.
 * - ν: Precision times mean.
 * - c: Offset.
 * - Λ: Precision.
 * - α: Shape of the inverse-gamma.
 * - β: Scale of the inverse-gamma.
 */
function simulate_dot_multivariate_normal_inverse_gamma_gaussian(
    a:Real[_], ν:Real[_], c:Real, Λ:LLT, α:Real, β:Real) -> Real {
  return simulate_student_t(2.0*α, dot(a, solve(Λ, ν)) + c,
      (β/α)*(1.0 + dot(a, solve(Λ, a))));
}

/**
 * Simulate a matrix Gaussian distribution.
 *
 * - M: Mean.
 * - U: Within-row covariance.
 * - V: Within-column covariance.
 */
function simulate_matrix_gaussian(M:Real[_,_], U:Real[_,_], V:Real[_,_]) ->
    Real[_,_] {
  auto N <- rows(M);
  auto P <- columns(M);
  Z:Real[N,P];
  for auto n in 1..N {
    for auto p in 1..P {
      Z[n,p] <- simulate_gaussian(0.0, 1.0);
    }
  }
  return M + cholesky(U)*Z*transpose(cholesky(V));
}

/**
 * Simulate a matrix Gaussian distribution with independent columns.
 *
 * - M: Mean.
 * - U: Within-row covariance.
 * - σ2: Within-column variances.
 */
function simulate_independent_matrix_gaussian(M:Real[_,_], U:Real[_,_],
    σ2:Real[_]) -> Real[_,_] {
  auto N <- rows(M);
  auto P <- columns(M);
  X:Real[N,P];
  for auto p in 1..P {
    X[1..N,p] <- simulate_multivariate_gaussian(M[1..N,p], U*σ2[p]);
  }
  return X;
}

/**
 * Simulate a matrix normal-inverse-gamma distribution.
 *
 * - N: Precision times mean matrix.
 * - Λ: Precision.
 * - α: Variance shapes.
 * - β: Variance scales.
 */
function simulate_matrix_normal_inverse_gamma(N:Real[_,_], Λ:LLT, α:Real[_],
    β:Real[_]) -> Real[_,_] {
  auto R <- rows(N);
  auto C <- columns(N);
  auto M <- solve(Λ, N);
  X:Real[R,C];
  for auto j in 1..C {
    X[1..R,j] <- simulate_multivariate_student_t(2.0*α[j], M[1..R,j],
        (β[j]/α[j])*inv(Λ));
  }    
  return X;
}

/**
 * Simulate a Gaussian distribution with matrix normal inverse-gamma prior.
 *
 * - a: Scale.
 * - N: Precision times mean matrix.
 * - Λ: Precision.
 * - α: Variance shapes.
 * - β: Variance scales.
 */
function simulate_dot_matrix_normal_inverse_gamma_multivariate_gaussian(
    a:Real[_], N:Real[_,_], Λ:LLT, α:Real[_], β:Real[_]) -> Real[_] {
  auto D <- columns(N);
  auto M <- solve(Λ, N);
  auto μ <- transpose(M)*a;
  auto c <- dot(a, solve(Λ, a));
  x:Real[D];
  for auto d in 1..D {
    x[d] <- simulate_student_t(2.0*α[d], μ[d], (β[d]/α[d])*(1.0 + c));
  }
  return x;
}

/**
 * Simulate a multivariate Student's $t$-distribution variate with
 * location and scale.
 *
 * - k: Degrees of freedom.
 * - μ: Mean.
 * - Σ: Covariance.
 */
function simulate_multivariate_student_t(k:Real, μ:Real[_], Σ:Real[_,_]) ->
    Real[_] {
  auto D <- length(μ);
  z:Real[D];
  for auto d in 1..D {
    z[d] <- simulate_student_t(k);
  }
  return μ + cholesky(Σ)*z;
}

/**
 * Simulate a multivariate Student's $t$-distribution variate with
 * location and diagonal scaling.
 *
 * - k: Degrees of freedom.
 * - μ: Mean.
 * - σ2: Variance.
 */
function simulate_multivariate_student_t(k:Real, μ:Real[_], σ2:Real) ->
    Real[_] {
  auto D <- length(μ);
  auto σ <- sqrt(σ2);
  z:Real[D];
  for auto d in 1..D {
    z[d] <- μ[d] + σ*simulate_student_t(k);
  }
  return z;
}

/**
 * Simulate a multivariate uniform distribution.
 *
 * - l: Lower bound of hyperrectangle.
 * - u: Upper bound of hyperrectangle.
 */
function simulate_independent_uniform(l:Real[_], u:Real[_]) -> Real[_] {
  assert length(l) == length(u);
  D:Integer <- length(l);
  z:Real[D];
  for (d:Integer in 1..D) {
    z[d] <- simulate_uniform(l[d], u[d]);
  }
  return z;
}

/**
 * Simulate a multivariate uniform distribution over integers.
 *
 * - l: Lower bound of hyperrectangle.
 * - u: Upper bound of hyperrectangle.
 */
function simulate_independent_uniform_int(l:Integer[_], u:Integer[_]) -> Integer[_] {
  assert length(l) == length(u);
  D:Integer <- length(l);
  z:Integer[D];
  for d:Integer in 1..D {
    z[d] <- simulate_uniform_int(l[d], u[d]);
  }
  return z;
}

/**
 * Simulate ridge regression parameters.
 *
 * - N: Prior precision times mean for weights, where each column represents
 *      the mean of the weight for a separate output. 
 * - Λ: Common prior precision.
 * - α: Common prior weight and likelihood covariance shape.
 * - β: Prior covariance scale accumulators.
 *
 * Returns: Matrix of weights and vector of variances, where each column in
 * the matrix and element in the vector corresponds to a different output
 * in the regression.
 */
function simulate_ridge(N:Real[_,_], Λ:LLT, α:Real, γ:Real[_]) ->
    (Real[_,_], Real[_]) {
  auto R <- rows(N);
  auto C <- columns(N);
  auto M <- solve(Λ, N);
  auto Σ <- inv(Λ);
  auto β <- γ - 0.5*diagonal(transpose(N)*M);
    
  W:Real[R,C];
  σ2:Real[C];
  for auto j in 1..C {
    σ2[j] <- simulate_inverse_gamma(α, β[j]);
    W[1..R,j] <- simulate_multivariate_gaussian(M[1..R,j], Σ*σ2[j]);
  }    
  return (W, σ2);
}

/**
 * Simulate regression.
 *
 * - W: Weight matrix, where each column represents the weights for a
 *      different output. 
 * - σ2: Variance vector, where each element represents the variance for a
 *      different output.
 * - u: Input.
 *
 * Returns: Outputs of the regression.
 */
function simulate_regression(W:Real[_,_], σ2:Real[_], u:Real[_]) -> Real[_] {
  auto μ <- transpose(W)*u;
  auto D <- length(μ);
  x:Real[D];
  for auto d in 1..D {
    x[d] <- simulate_gaussian(μ[d], σ2[d]);
  }
  return x;
}

/**
 * Simulate ridge regression.
 *
 * - N: Prior precision times mean for weights, where each column represents
 *      the mean of the weight for a separate output. 
 * - Λ: Common prior precision.
 * - α: Common prior weight and likelihood covariance shape.
 * - β: Prior covariance scale accumulators.
 * - u: Input.
 */
function simulate_ridge_regression(N:Real[_,_], Λ:LLT, α:Real, γ:Real[_],
    u:Real[_]) -> Real[_] {
  D:Integer <- columns(N);
  M:Real[_,_] <- solve(Λ, N);
  μ:Real[_] <- transpose(M)*u;
  σ2:Real[_] <- (γ - 0.5*diagonal(transpose(N)*M))*(1.0 + dot(u, solve(Λ, u)))/α;  
  x:Real[D];
  for d:Integer in 1..D {
    x[d] <- simulate_student_t(2.0*α, μ[d], σ2[d]);
  }
  return x;
}
