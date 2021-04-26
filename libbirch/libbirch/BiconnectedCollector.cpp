/**
 * @file
 */
#include "libbirch/BiconnectedCollector.hpp"

void libbirch::BiconnectedCollector::visit(Any* o) {
  auto old = o->f_.exchangeOr(COLLECTED);
  if (!(old & COLLECTED)) {
    o->accept_(*this);
  }
}
