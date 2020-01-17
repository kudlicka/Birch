/**
 * Event triggered for a factor.
 *
 * - w: Associated (log-)weight.
 */
final class FactorEvent(w:Real) < Event {
  /**
   * Associated (log-)weight.
   */
  w:Real <- w;

  function play() -> Real {
    return w;
  }

  function replay(record:Record) -> Real {
    return w;
  }
  
  function record() -> Record {
    return FactorRecord(w);
  }
}

/**
 * Create a FactorEvent.
 */
function FactorEvent(w:Real) -> FactorEvent {
  evt:FactorEvent(w);
  return evt;
}
