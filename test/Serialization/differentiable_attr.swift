// SWIFT_ENABLE_TENSORFLOW
// TODO: Handle trailing where clause in @differentiable attribute.

// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend %s -emit-module -parse-as-library -o %t
// RUN: %target-sil-opt -disable-sil-linking -enable-sil-verify-all %t/differentiable_attr.swiftmodule -o - | %FileCheck %s

struct CheckpointsFoo {}
func pfoo(_ x: Float) -> (checkpoints: CheckpointsFoo, originalValue: Float) {
  return (CheckpointsFoo(), x * x)
}
func dfoo_checkpointed(_ seed: Float, _ checkpoints: CheckpointsFoo, _ originalValue: Float, _ x: Float) -> Float {
  return 2 * x
}
// CHECK-DAG: @differentiable(primal: pfoo, adjoint: dfoo_checkpointed)
// CHECK-DAG: func foo_checkpointed(_ x: Float) -> Float
@differentiable(primal: pfoo(_:), adjoint: dfoo_checkpointed)
func foo_checkpointed(_ x: Float) -> Float {
  return x * x
}

struct S<T> {
  struct Checkpoints {
    let s: S
  }
  func primal(x: Float) -> (Checkpoints, Float) {
    return (Checkpoints(s: self), x)
  }
  func adjoint_checkpointed(_: Float, _: Checkpoints, _: Float, _ x: Float) -> S {
    return self
  }

  // CHECK-DAG: @differentiable(wrt: (self), primal: primal, adjoint: adjoint_checkpointed)
  // CHECK-DAG: func original(x: Float) -> Float
  @differentiable(wrt: (self), primal: primal, adjoint: adjoint_checkpointed)
  func original(x: Float) -> Float {
    return x
  }
}

extension S : Differentiable, VectorNumeric {
  typealias TangentVector = S
  typealias CotangentVector = S
  typealias Scalar = Float
  static var zero: S { fatalError("unimplemented") }
  static func + (lhs: S, rhs: S) -> S { fatalError("unimplemented") }
  static func - (lhs: S, rhs: S) -> S { fatalError("unimplemented") }
  static func * (lhs: Float, rhs: S) -> S { fatalError("unimplemented") }
}

func pbaz1<T : Differentiable>(_ x: T, _ y: T) -> ((T, T), T) {
  return ((y, y), x)
}
func dbaz1_checkpointed<T : Differentiable>(_ seed: T.CotangentVector, _ primal: (T, T), _ originalValue: T, _ x: T, _ y: T) -> (T.CotangentVector, T.CotangentVector) {
  return (seed, seed)
}
// CHECK-DAG: @differentiable(primal: pbaz1, adjoint: dbaz1_checkpointed)
// CHECK-DAG: func baz1_checkpointed<T>(_ x: T, _ y: T) -> T
@differentiable(primal: pbaz1(_:_:), adjoint: dbaz1_checkpointed)
func baz1_checkpointed<T : Differentiable>(_ x: T, _ y: T) -> T {
  return x
}

struct CheckpointsFP<T : FloatingPoint> {
  let meow: T
}
func pbaz2<T : Differentiable & FloatingPoint>(_ x: T, _ y: T) -> (CheckpointsFP<T>, T) {
  return (CheckpointsFP(meow: 1), x + y)
}
func dbaz2_checkpointed<T : Differentiable & FloatingPoint>(_ seed: T.CotangentVector, _ primal: CheckpointsFP<T>, _ originalValue: T, _ x: T, _ y: T) -> (T.CotangentVector, T.CotangentVector) {
  return (seed, seed)
}
// CHECK-DAG: @differentiable(primal: pbaz2, adjoint: dbaz2_checkpointed)
// CHECK-DAG: func baz2_checkpointed<T>(_ x: T, _ y: T) -> T where T : Differentiable, T : FloatingPoint
@differentiable(primal: pbaz2(_:_:), adjoint: dbaz2_checkpointed)
func baz2_checkpointed<T : Differentiable & FloatingPoint>(_ x: T, _ y: T) -> T {
  return x
}

@differentiable(jvp: jvpSimpleJVP)
func jvpSimple(x: Float) -> Float {
  return x
}

// CHECK-DAG: @differentiable(jvp: jvpSimpleJVP)
// CHECK-DAG: func jvpSimpleJVP(x: Float) -> (Float, (Float) -> Float)
func jvpSimpleJVP(x: Float) -> (Float, (Float) -> Float) {
  return (x, { v in v })
}

@differentiable(vjp: vjpSimpleVJP)
func vjpSimple(x: Float) -> Float {
  return x
}

// CHECK-DAG: @differentiable(vjp: vjpSimpleVJP)
// CHECK-DAG: func vjpSimpleVJP(x: Float) -> (Float, (Float) -> Float)
func vjpSimpleVJP(x: Float) -> (Float, (Float) -> Float) {
  return (x, { v in v })
}