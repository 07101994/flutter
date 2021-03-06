// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';

/// A message encoding/decoding mechanism.
///
/// Both operations throw [FormatException], if conversion fails.
///
/// See also:
///
/// * [PlatformMessageChannel], which use [MessageCodec]s for communication
///   between Flutter and platform plugins.
abstract class MessageCodec<T> {
  /// Encodes the specified [message] in binary.
  ///
  /// Returns `null` if the message is `null`.
  ByteData encodeMessage(T message);

  /// Decodes the specified [message] from binary.
  ///
  /// Returns `null` if the message is `null`.
  T decodeMessage(ByteData message);
}

/// An command object representing the invocation of a named method.
class MethodCall {
  /// Creates a [MethodCall] representing the invocation of [method] with the
  /// specified [arguments].
  MethodCall(this.method, [this.arguments]) {
    assert(method != null);
  }

  /// The name of the method to be called.
  final String method;

  /// The arguments for the method.
  ///
  /// Must be a valid value for the [MethodCodec] used.
  final dynamic arguments;

  @override
  bool operator == (dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    return method == other.method && _deepEquals(arguments, other.arguments);
  }

  @override
  int get hashCode => hashValues(method, arguments);

  bool _deepEquals(dynamic a, dynamic b) {
    if (a == b)
      return true;
    if (a is List)
      return b is List && _deepEqualsList(a, b);
    if (a is Map)
      return b is Map && _deepEqualsMap(a, b);
    return false;
  }

  bool _deepEqualsList(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length)
      return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i]))
        return false;
    }
    return true;
  }

  bool _deepEqualsMap(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    if (a.length != b.length)
      return false;
    for (dynamic key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key]))
        return false;
    }
    return true;
  }

  @override
  String toString() => '$runtimeType($method, $arguments)';
}

/// A codec for method calls and enveloped results.
///
/// Result envelopes are binary messages with enough structure that the codec can
/// distinguish between a successful result and an error. In the former case,
/// the codec must be able to extract the result payload, possibly `null`. In
/// the latter case, the codec must be able to extract an error code string,
/// a (human-readable) error message string, and a value providing any
/// additional error details, possibly `null`. These data items are used to
/// populate a [PlatformException].
///
/// All operations throw [FormatException], if conversion fails.
///
/// See also:
///
/// * [PlatformMethodChannel], which use [MethodCodec]s for communication
///   between Flutter and platform plugins.
/// * [PlatformEventChannel], which use [MethodCodec]s for communication
///   between Flutter and platform plugins.
abstract class MethodCodec {
  /// Encodes the specified [methodCall] in binary.
  ByteData encodeMethodCall(MethodCall methodCall);

  /// Decodes the specified [methodCall] from binary.
  MethodCall decodeMethodCall(ByteData methodCall);

  /// Decodes the specified result [envelope] from binary.
  ///
  /// Throws [PlatformException], if [envelope] represents an error, otherwise
  /// returns the enveloped result.
  dynamic decodeEnvelope(ByteData envelope);

  /// Encodes a successful [result] into a binary envelope.
  ByteData encodeSuccessEnvelope(dynamic result);

  /// Encodes an error result into a binary envelope.
  ///
  /// The specified error [code], human-readable error [message], and error
  /// [details] correspond to the fields of [PlatformException].
  ByteData encodeErrorEnvelope({@required String code, String message, dynamic details});
}


/// Thrown to indicate that a platform interaction failed in the platform
/// plugin.
///
/// See also:
///
/// * [MethodCodec], which throws a [PlatformException], if a received result
///   envelope represents an error.
/// * [PlatformMethodChannel.invokeMethod], which completes the returned future
///   with a [PlatformException], if invoking the platform plugin method
///   results in an error envelope.
/// * [PlatformEventChannel.receiveBroadcastStream], which emits
///   [PlatformException]s as error events, whenever an event received from the
///   platform plugin is wrapped in an error envelope.
class PlatformException implements Exception {
  /// Creates a [PlatformException] with the specified error [code] and optional
  /// [message], and with the optional error [details] which must be a valid
  /// value for the [MethodCodec] involved in the interaction.
  PlatformException({
    @required this.code,
    this.message,
    this.details,
  }) {
    assert(code != null);
  }

  /// An error code.
  final String code;

  /// A human-readable error message, possibly `null`.
  final String message;

  /// Error details, possibly `null`.
  final dynamic details;

  @override
  String toString() => 'PlatformException($code, $message, $details)';
}

/// Thrown to indicate that a platform interaction failed to find a handling
/// plugin.
///
/// See also:
///
/// * [PlatformMethodChannel.invokeMethod], which completes the returned future
///   with a [MissingPluginException], if no plugin handler for the method call
///   was found.
class MissingPluginException implements Exception {
  /// Creates a [MissingPluginException] with an optional human-readable
  /// error message.
  MissingPluginException([this.message]);

  /// A human-readable error message, possibly `null`.
  final String message;

  @override
  String toString() => 'MissingPluginException($message)';
}
