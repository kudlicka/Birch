/**
 * @file
 *
 * Standard headers that should be included for all C++ files generated by
 * the compiler.
 */
#pragma once

#include "libbirch/external.hpp"
#include "libbirch/assert.hpp"
#include "libbirch/memory.hpp"
#include "libbirch/stacktrace.hpp"
#include "libbirch/class.hpp"
#include "libbirch/basic.hpp"
#include "libbirch/type.hpp"
#include "libbirch/thread.hpp"
#include "libbirch/operation.hpp"

#include "libbirch/SharedPtr.hpp"
#include "libbirch/WeakPtr.hpp"
#include "libbirch/InitPtr.hpp"
#include "libbirch/Lazy.hpp"
#include "libbirch/Dimension.hpp"
#include "libbirch/Index.hpp"
#include "libbirch/Range.hpp"
#include "libbirch/Shape.hpp"
#include "libbirch/Slice.hpp"
#include "libbirch/Array.hpp"
#include "libbirch/Tuple.hpp"
#include "libbirch/Tie.hpp"
#include "libbirch/Any.hpp"
#include "libbirch/Optional.hpp"
#include "libbirch/Nil.hpp"
#include "libbirch/Fiber.hpp"
#include "libbirch/Eigen.hpp"
#include "libbirch/EigenFunctions.hpp"
#include "libbirch/EigenOperators.hpp"

/**
 * LibBirch.
 */
namespace libbirch {
/**
 * Default array for `D` dimensions.
 */
template<class T, int D>
using DefaultArray = Array<T,typename DefaultShape<D>::type>;

/**
 * Default slice for `D`-dimensional indexing of a single element.
 */
template<int D>
struct DefaultSlice {
  typedef Slice<Index<>,typename DefaultSlice<D - 1>::type> type;
};
template<>
struct DefaultSlice<0> {
  typedef EmptySlice type;
};

/**
 * Lazy shared pointer.
 */
template<class T>
using LazySharedPtr = Lazy<SharedPtr<T>>;

/**
 * Lazy weak pointer.
 */
template<class T>
using LazyWeakPtr = Lazy<WeakPtr<T>>;

/**
 * Lazy init pointer.
 */
template<class T>
using LazyInitPtr = Lazy<InitPtr<T>>;

/**
 * Make a range.
 *
 * @ingroup libbirch
 *
 * @param start First index.
 * @param end Last index.
 */
inline Range<> make_range(const int64_t start, const int64_t end) {
  int64_t length = std::max(int64_t(0), end - start + 1);
  return Range<>(start, length);
}

/**
 * Make a shape, no arguments.
 *
 * @ingroup libbirch
 */
inline EmptyShape make_shape() {
  return EmptyShape();
}

/**
 * Make a shape, single argument.
 *
 * @ingroup libbirch
 */
inline Shape<Dimension<>,EmptyShape> make_shape(const int64_t arg) {
  auto tail = EmptyShape();
  auto head = Dimension<>(arg, tail.volume());
  return Shape<Dimension<>,EmptyShape>(head, tail);
}

/**
 * Make a shape, multiple arguments.
 *
 * @ingroup libbirch
 */
template<class ... Args>
auto make_shape(const int64_t arg, Args ... args) {
  auto tail = make_shape(args...);
  auto head = Dimension<>(arg, tail.volume());
  return Shape<decltype(head),decltype(tail)>(head, tail);
}

/**
 * Make a shape, recursively.
 *
 * @ingroup libbirch
 */
template<class ... Args>
auto make_shape(const int64_t arg, const Shape<Args...>& tail) {
  auto head = Dimension<>(arg, tail.volume());
  return Shape<decltype(head),decltype(tail)>(head, tail);
}

/**
 * Make a slice, no arguments.
 *
 * @ingroup libbirch
 */
inline EmptySlice make_slice() {
  return EmptySlice();
}

/**
 * Make a slice, single argument.
 *
 * @ingroup libbirch
 */
template<int64_t offset_value, int64_t length_value>
auto make_slice(const Range<offset_value,length_value>& arg) {
  auto head = arg;
  auto tail = make_slice();
  return Slice<decltype(head),decltype(tail)>(head, tail);
}

/**
 * Make a slice, single argument.
 *
 * @ingroup libbirch
 */
inline Slice<Index<>,EmptySlice> make_slice(const int64_t arg) {
  auto head = Index<>(arg);
  auto tail = EmptySlice();
  return Slice<Index<>,EmptySlice>(head, tail);
}

/**
 * Make a slice, multiple arguments.
 *
 * @ingroup libbirch
 */
template<int64_t offset_value, int64_t length_value, class ... Args>
auto make_slice(const Range<offset_value,length_value>& arg, Args ... args) {
  auto head = arg;
  auto tail = make_slice(args...);
  return Slice<decltype(head),decltype(tail)>(head, tail);
}

/**
 * Make a slice, multiple arguments.
 *
 * @ingroup libbirch
 */
template<class ... Args>
auto make_slice(const int64_t arg, Args ... args) {
  auto head = Index<mutable_value>(arg);
  auto tail = make_slice(args...);
  return Slice<decltype(head),decltype(tail)>(head, tail);
}

/**
 * Make an array of value type.
 *
 * @ingroup libbirch
 *
 * @tparam T Value type.
 * @tparam F Shape type.
 * @tparam Args Constructor parameter types.
 *
 * @param shape Shape.
 * @param args Constructor arguments.
 *
 * @return The array.
 */
template<class T, class F, class ... Args>
Array<T,F> make_array(const F& shape, const Args&... args) {
  return Array<T,F>(shape, args...);
}

/**
 * Make an array of non-value type.
 *
 * @ingroup libbirch
 *
 * @tparam T Value type.
 * @tparam F Shape type.
 * @tparam Args Constructor parameter types.
 *
 * @param context Current context.
 * @param shape Shape.
 * @param args Constructor arguments.
 *
 * @return The array.
 */
template<class T, class F, class ... Args>
Array<T,F> make_array(Label* context, const F& shape,
    const Args&... args) {
  return Array<T,F>(context, shape, args...);
}

/**
 * Make an array and assign a value to it.
 *
 * @ingroup libbirch
 *
 * @tparam T Value type.
 * @tparam F Shape type.
 * @tparam Value Initial value type.
 *
 * @param shape Shape.
 * @param value Initial value.
 *
 * @return The array.
 */
template<class T, class F, class Value>
Array<T,F> make_array_and_assign(const F& shape,
    const Value& value) {
  Array<T,F> result;
  result.enlarge(shape, value);
  return result;
}

/**
 * Make a pointer, with in-place object construction.
 *
 * @ingroup libbirch
 *
 * @tparam P Pointer type.
 * @tparam Args Constructor parameter types.
 *
 * @param context Current context.
 * @param args Constructor arguments.
 *
 * @return A pointer of the given type.
 */
template<class P, class ... Args>
P make_pointer(Label* context, const Args& ... args) {
  return P(context, new typename P::value_type(context, args...));
}

/**
 * Make a tuple.
 *
 * @tparam Head First element type.
 * @tparam Tail Remaining element types.
 *
 * @param head First element.
 * @param tail Remaining elements.
 */
template<class Head, class... Tail>
Tuple<Head,Tail...> make_tuple(const Head& head, const Tail&... tail) {
  return Tuple<Head,Tail...>(head, tail...);
}

/**
 * Make a tuple.
 *
 * @tparam Head First element type.
 * @tparam Tail Remaining element types.
 *
 * @param head First element.
 * @param tail Remaining elements.
 */
template<class Head, class... Tail>
Tuple<Head,Tail...> make_tuple(Label* context, const Head& head,
    const Tail&... tail) {
  return Tuple<Head,Tail...>(context, head, tail...);
}

/**
 * Make an assignable tuple.
 *
 * @tparam Head First element type.
 * @tparam Tail Remaining element types.
 *
 * @param head First element.
 * @param tail Remaining elements.
 */
template<class Head, class... Tail>
Tie<Head&,Tail&...> tie(Head& head, Tail&... tail) {
  return Tie<Head&,Tail&...>(head, tail...);
}

/**
 * Make an assignable tuple.
 *
 * @tparam Head First element type.
 * @tparam Tail Remaining element types.
 *
 * @param head First element.
 * @param tail Remaining elements.
 */
template<class Head, class... Tail>
Tie<Head&,Tail&...> tie(Label* context, Head& head, Tail&... tail) {
  return Tie<Head&,Tail&...>(context, head, tail...);
}

/**
 * Make a value.
 *
 * @tparam T Value type.
 *
 * @return An optional with a default-constructed value of the given type.
 */
template<class T, IS_VALUE(T)>
Optional<T> make(Label* context) {
  return Optional<T>(T());
}

/**
 * Make an object.
 *
 * @tparam T Pointer type.
 *
 * @return An optional with a value of the given type if that type is
 * a default-constructible class type, otherwise no value.
 */
template<class T, IS_DEFAULT_CONSTRUCTIBLE(T)>
Optional<T> make(Label* context) {
  return Optional<T>(make_pointer<T>(context));
}

/**
 * Make an object.
 *
 * @tparam T Pointer type.
 *
 * @return An optional with a value of the given type if that type is
 * a default-constructible class type, otherwise no value.
 */
template<class T, IS_NOT_DEFAULT_CONSTRUCTIBLE(T)>
Optional<T> make(Label* context) {
  return Optional<T>();
}

/**
 * Cast an object.
 */
template<class To, class From>
Optional<To> dynamic_pointer_cast(Label* context, const LazySharedPtr<From>& from) {
  return Optional<To>(context, from.template dynamic_pointer_cast<To>(context));
}

/**
 * Cast an object optional.
 */
template<class To, class From>
Optional<To> dynamic_pointer_cast(Label* context, const Optional<LazySharedPtr<From>>& from) {
  if (from.query()) {
    return Optional<To>(context, from.get().template dynamic_pointer_cast<To>(context));
  } else {
    return Optional<To>();
  }
}

/**
 * Cast anything else.
 *
 * @return An optional, with a value only if @p from is of type To.
 */
template<class To, class From>
Optional<To> check_cast(const From& from) {
  return std::is_same<To,From>::value ? Optional<To>(from) : Optional<To>();
}

/**
 * Cast an optional of anything else.
 *
 * @return An optional, with a value only if @p from has a value of type To.
 */
template<class To, class From>
Optional<To> check_cast(const Optional<From>& from) {
  if (from.query()) {
    return check_cast<To>(from.get());
  } else {
    return Optional<To>();
  }
}

}
