/**
 * @file
 */
#pragma once

#include "bi/statement/Statement.hpp"
#include "bi/common/Named.hpp"
#include "bi/common/Numbered.hpp"
#include "bi/common/Parameterised.hpp"
#include "bi/common/ReturnTyped.hpp"
#include "bi/common/Braced.hpp"
#include "bi/common/Scoped.hpp"

namespace bi {
/**
 * Class member coroutine.
 *
 * @ingroup compiler_statement
 */
class MemberCoroutine: public Statement,
    public Named,
    public Numbered,
    public Parameterised,
    public ReturnTyped,
    public Typed,
    public Scoped,
    public Braced {
public:
  /**
   * Constructor.
   *
   * @param name Name.
   * @param params Parameters.
   * @param returnType Return type.
   * @param braces Body.
   * @param loc Location.
   */
  MemberCoroutine(Name* name, Expression* params, Type* returnType,
      Statement* braces, Location* loc = nullptr);

  /**
   * Destructor.
   */
  virtual ~MemberCoroutine();

  virtual Statement* accept(Cloner* visitor) const;
  virtual Statement* accept(Modifier* visitor);
  virtual void accept(Visitor* visitor) const;
};
}