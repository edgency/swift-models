// Copyright 2020 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
  import Darwin
#elseif os(Windows)
  import ucrt
#else
  import Glibc
#endif

/// logSumExp(_:_:)
///
/// Specialized logSumExp for 2 float.
@differentiable
public func logSumExp(_ lhs: Float, _ rhs: Float) -> Float {
  let maxVal = max(lhs, rhs)
  let sumExp = exp(lhs - maxVal) + exp(rhs - maxVal)
  return maxVal + log(sumExp)
}

@derivative(of: logSumExp)
public func vjpLogSumExp(_ lhs: Float, _ rhs: Float) -> (
  value: Float,
  pullback: (Float) -> (Float, Float)
) {
  func pb(v: Float) -> (Float, Float) {
    let maxVal = max(lhs, rhs)
    let sumExp = exp(lhs - maxVal) + exp(rhs - maxVal)
    return (v * exp(lhs - maxVal) / sumExp, v * exp(rhs - maxVal) / sumExp)
  }
  return (logSumExp(lhs, rhs), pb)
}

/// SemiRing
///
/// Represents a SemiRing
public struct SemiRing: Differentiable {
  public var logp: Float
  public var logr: Float

  @differentiable
  public init(logp: Float, logr: Float) {
    self.logp = logp
    self.logr = logr
  }

  static var zero: SemiRing { SemiRing(logp: -Float.infinity, logr: -Float.infinity) }
  static var one: SemiRing { SemiRing(logp: 0.0, logr: -Float.infinity) }
}

@differentiable
func * (_ lhs: SemiRing, _ rhs: SemiRing) -> SemiRing {
  return SemiRing(
    logp: lhs.logp + rhs.logp,
    logr: logSumExp(lhs.logp + rhs.logr, rhs.logp + lhs.logr))
}

@differentiable
func + (_ lhs: SemiRing, _ rhs: SemiRing) -> SemiRing {
  return SemiRing(
    logp: logSumExp(lhs.logp, rhs.logp),
    logr: logSumExp(lhs.logr, rhs.logr))
}

extension SemiRing {
  var shortDescription: String {
    "(\(logp), \(logr))"
  }
}

/// SE-0259-esque equality with tolerance
extension SemiRing {
  // TODO(abdulras) see if we can use ulp as a default tolerance
  @inlinable
  public func isAlmostEqual(to other: Self, tolerance: Float) -> Bool {
    return self.logp.isAlmostEqual(to: other.logp, tolerance: tolerance)
      && self.logr.isAlmostEqual(to: other.logr, tolerance: tolerance)
  }
}
