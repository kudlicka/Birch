/**
 * @file
 */
#pragma once

#include "bi/type/Type.hpp"
#include "bi/common/Overloaded.hpp"
#include "bi/primitive/poset.hpp"
#include "bi/primitive/definitely.hpp"

namespace bi {
/**
 * Overloaded type. Typically used for the type of first-class functions.
 *
 * @ingroup common
 */
class OverloadedType: public Type {
public:
  /**
   * Constructor.
   *
   * @param overloaded Overloaded object.
   * @param loc Location.
   */
  OverloadedType(Overloaded* overloaded, const std::list<Overloaded*>& others, Location* loc = nullptr);

  /**
   * Destructor.
   */
  virtual ~OverloadedType();

  virtual Type* accept(Cloner* visitor) const;
  virtual Type* accept(Modifier* visitor);
  virtual void accept(Visitor* visitor) const;

  virtual bool isOverloaded() const;
  virtual FunctionType* resolve(Argumented* args);
  virtual FunctionType* resolve() const;

  using Type::definitely;
  using Type::common;

  virtual bool dispatchDefinitely(const Type& o) const;
  virtual bool definitely(const OverloadedType& o) const;
  virtual bool definitely(const FunctionType& o) const;

  virtual Type* dispatchCommon(const Type& o) const;
  virtual Type* common(const OverloadedType& o) const;
  virtual Type* common(const FunctionType& o) const;

  /**
   * Overloaded object.
   */
  Overloaded* overloaded;

  /**
   * Alternative overloaded objects.
   */
  std::list<Overloaded*> others;

  /**
   * Overloads.
   */
  poset<Parameterised*,bi::definitely> overloads;
};
}
