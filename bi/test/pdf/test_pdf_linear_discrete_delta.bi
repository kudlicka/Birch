/*
 * Test linear-discrete-delta pdf evaluations.
 */
program test_pdf_linear_discrete_delta(N:Integer <- 10000) {
  m:TestLinearDiscreteDelta;
  m.play();
  test_pdf(m.marginal(), N);
}
