/**
 * Lazy multivariate add.
 */
final class MultivariateAdd<Left,Right,Value>(left:Expression<Left>,
    right:Expression<Right>) < BinaryExpression<Left,Right,Value>(left, right) {  
  function rows() -> Integer {
    assert left.rows() == right.rows();
    return left.rows();
  }

  function doValue(l:Left, r:Right) -> Value {
    return l + r;
  }

  function doGradient(d:Value, l:Left, r:Right) -> (Left, Right) {
    return (d, d);
  }

  function graftLinearMultivariateGaussian() ->
      TransformLinearMultivariate<MultivariateGaussian>? {
    y:TransformLinearMultivariate<MultivariateGaussian>?;
    z:MultivariateGaussian?;

    if (y <- left.graftLinearMultivariateGaussian())? {
      y!.add(right);
    } else if (y <- right.graftLinearMultivariateGaussian())? {
      y!.add(left);
    } else if (z <- left.graftMultivariateGaussian())? {
      y <- TransformLinearMultivariate<MultivariateGaussian>(
          Boxed(identity(z!.rows())), z!, right);
    } else if (z <- right.graftMultivariateGaussian())? {
      y <- TransformLinearMultivariate<MultivariateGaussian>(
          Boxed(identity(z!.rows())), z!, left);
    }
    return y;
  }
  
  function graftLinearMultivariateNormalInverseGamma() ->
      TransformLinearMultivariate<MultivariateNormalInverseGamma>? {
    y:TransformLinearMultivariate<MultivariateNormalInverseGamma>?;
    z:MultivariateNormalInverseGamma?;

    if (y <- left.graftLinearMultivariateNormalInverseGamma())? {
      y!.add(right);
    } else if (y <- right.graftLinearMultivariateNormalInverseGamma())? {
      y!.add(left);
    } else if (z <- left.graftMultivariateNormalInverseGamma())? {
      y <- TransformLinearMultivariate<MultivariateNormalInverseGamma>(
          Boxed(identity(z!.rows())), z!, right);
    } else if (z <- right.graftMultivariateNormalInverseGamma())? {
      y <- TransformLinearMultivariate<MultivariateNormalInverseGamma>(
          Boxed(identity(z!.rows())), z!, left);
    }
    return y;
  }
}

/**
 * Lazy multivariate add.
 */
operator (left:Expression<Real[_]> + right:Expression<Real[_]>) ->
    MultivariateAdd<Real[_],Real[_],Real[_]> {
  assert left.rows() == right.rows();
  m:MultivariateAdd<Real[_],Real[_],Real[_]>(left, right);
  return m;
}

/**
 * Lazy multivariate add.
 */
operator (left:Real[_] + right:Expression<Real[_]>) ->
    MultivariateAdd<Real[_],Real[_],Real[_]> {
  return Boxed(left) + right;
}

/**
 * Lazy multivariate add.
 */
operator (left:Expression<Real[_]> + right:Real[_]) ->
    MultivariateAdd<Real[_],Real[_],Real[_]> {
  return left + Boxed(right);
}
