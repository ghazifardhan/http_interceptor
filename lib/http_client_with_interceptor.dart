import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:http_interceptor/m_r.dart';
import 'package:http_interceptor/models/merge_params.dart';
import 'package:http_interceptor/models/models.dart';
import 'package:http_interceptor/interceptor_contract.dart';

import 'http_methods.dart';

///Class to be used by the user to set up a new `http.Client` with interceptor supported.
///call the `build()` constructor passing in the list of interceptors.
///Example:
///```dart
/// HttpClientWithInterceptor httpClient = HttpClientWithInterceptor.build(interceptors: [
///     Logger(),
/// ]);
///```
///
///Then call the functions you want to, on the created `http` object.
///```dart
/// httpClient.get(...);
/// httpClient.post(...);
/// httpClient.put(...);
/// httpClient.delete(...);
/// httpClient.head(...);
/// httpClient.patch(...);
/// httpClient.read(...);
/// httpClient.readBytes(...);
/// httpClient.send(...);
/// httpClient.close();
///```
///Don't forget to close the client once you are done, as a client keeps
///the connection alive with the server.
class HttpClientWithInterceptor extends BaseClient {
  List<InterceptorContract> interceptors; // 所有拦截器
  Duration requestTimeout;

  final Client _client = Client();

  HttpClientWithInterceptor._internal({this.interceptors, this.requestTimeout});

  factory HttpClientWithInterceptor.build({
    List<InterceptorContract> interceptors,
    Duration requestTimeout,
  }) {
    //Remove any value that is null.
    interceptors?.removeWhere((interceptor) => interceptor == null);
    return HttpClientWithInterceptor._internal(
      interceptors: interceptors,
      requestTimeout: requestTimeout,
    );
  }

  Future<Response> head(
    url, {
    Map<String, String> headers,
    Function(int bytes, int total) onProgress,
  }) =>
      _sendUnstreamed(
        method: Method.HEAD,
        url: url,
        headers: headers,
        onProgress: onProgress,
      );

  Future<Response> get(
    url, {
    Map<String, String> headers,
    Map<String, dynamic /*String|Iterable<String>*/ > params,
    Function(int bytes, int total) onProgress,
  }) =>
      _sendUnstreamed(
        method: Method.GET,
        url: url,
        headers: headers,
        params: params,
        onProgress: onProgress,
      );

  Future<Response> post(
    url, {
    Map<String, String> headers,
    body,
    Encoding encoding,
    Function(int bytes, int total) onProgress,
  }) =>
      _sendUnstreamed(
        method: Method.POST,
        url: url,
        headers: headers,
        body: body,
        encoding: encoding,
        onProgress: onProgress,
      );

  Future<Response> put(
    url, {
    Map<String, String> headers,
    body,
    Encoding encoding,
    Function(int bytes, int total) onProgress,
  }) =>
      _sendUnstreamed(
        method: Method.PUT,
        url: url,
        headers: headers,
        body: body,
        encoding: encoding,
        onProgress: onProgress,
      );

  Future<Response> patch(
    url, {
    Map<String, String> headers,
    body,
    Encoding encoding,
    Function(int bytes, int total) onProgress,
  }) =>
      _sendUnstreamed(
        method: Method.PATCH,
        url: url,
        headers: headers,
        body: body,
        encoding: encoding,
        onProgress: onProgress,
      );

  Future<Response> delete(
    url, {
    Map<String, String> headers,
    Function(int bytes, int total) onProgress,
  }) =>
      _sendUnstreamed(
        method: Method.DELETE,
        url: url,
        headers: headers,
        onProgress: onProgress,
      );

  Future<String> read(
    url, {
    Map<String, String> headers,
    Function(int bytes, int total) onProgress,
  }) {
    return get(
      url,
      headers: headers,
      onProgress: onProgress,
    ).then((response) {
      _checkResponseSuccess(url, response);
      return response.body;
    });
  }

  /// send file
  ///
  /// ```dart
  /// import 'dart:io';
  /// import 'package:async/async.dart';
  /// import 'package:http_interceptor/http_interceptor.dart';
  /// import 'package:image_picker/image_picker.dart';
  /// import 'package:http/http.dart';
  /// import 'package:path/path.dart';
  ///
  ///// Create http sender
  /// HttpClientWithInterceptor client = HttpClientWithInterceptor.build(
  ///   interceptors: [
  ///     BaseUrlInterceptor(),
  ///   ],
  /// );
  ///
  /// // Create an interceptor that will stitch the url
  /// class BaseUrlInterceptor implements InterceptorContract {
  ///   final baseUrl = "http://192.168.1.91:5000";
  ///   @override
  ///   Future<RequestData> interceptRequest({RequestData data}) async {
  ///     data.url = Uri.parse(baseUrl.toString() + data.url.toString());
  ///     return data;
  ///   }
  ///   @override
  ///   Future<ResponseData> interceptResponse({ResponseData data}) async {
  ///     return data;
  ///   }
  /// }
  ///
  /// floatingActionButton: FloatingActionButton(
  ///   child: Icon(Icons.add),
  ///   onPressed: () async {
  ///     // Get image
  ///     File imageFile =  await ImagePicker.pickImage(source: ImageSource.gallery);
  ///     if (imageFile != null) {
  ///       var stream = ByteStream(
  ///         DelegatingStream.typed(imageFile.openRead()),
  ///       );
  ///       int length = await imageFile.length();
  ///       MultipartFile file = MultipartFile(
  ///         'file',
  ///         stream,
  ///         length,
  ///         filename: basename(imageFile.path),
  ///       );
  ///       // send
  ///       var r = await client.postFile(
  ///        "/upload",
  ///         body: {
  ///           'name': 'foo',
  ///         },
  ///         files: [file],
  ///       );
  ///       print(r.statusCode);
  ///       print(r.body);
  ///     }
  ///   },
  /// ),
  /// ```
  Future<Response> postFile(
    url, {
    Map<String, String> headers,
    Map<String, String> body,
    List<MultipartFile> files,
    Function(int bytes, int total) onUploadProgress,
    Function(int bytes, int total) onProgress,
  }) =>
      _sendUnstreamed(
        method: Method.POST,
        url: url,
        headers: headers,
        body: body,
        files: files,
        onUploadProgress: onUploadProgress,
        onProgress: onProgress,
      );

  Future<Uint8List> readBytes(
    url, {
    Map<String, String> headers,
    Function(int bytes, int total) onProgress,
  }) {
    return get(
      url,
      headers: headers,
      onProgress: onProgress,
    ).then((response) {
      _checkResponseSuccess(url, response);
      return response.bodyBytes;
    });
  }

  Future<StreamedResponse> send(BaseRequest request) => _client.send(request);

  Future<Response> _sendUnstreamed({
    Method method,
    dynamic url,
    Map<String, String> headers,
    Map<String, dynamic /*String|Iterable<String>*/ > params,
    dynamic body,
    Encoding encoding,
    List<MultipartFile> files,
    Function(int bytes, int total) onUploadProgress,
    Function(int bytes, int total) onProgress,
  }) async {
    Uri paramUrl = url is Uri ? url : Uri.parse(url);
    var request = _createRequest(
      method: method,
      url: mergeParams(paramUrl, params),
      headers: headers,
      params: params,
      body: body,
      encoding: encoding,
      files: files,
      onUploadProgress: onUploadProgress,
    );

    // 运行request拦截器
    for (var it in interceptors) {
      RequestData r =
          await it.interceptRequest(data: RequestData.fromHttpRequest(request));
      request = files == null
          ? r.toHttpRequest<Request>()
          : r.toHttpRequest<MultipartRequest>();
    }

    var stream = requestTimeout == null
        ? await send(request)
        : await send(request).timeout(requestTimeout);

    List<int> bytes = [];
    var completer = Completer<Uint8List>();
    stream.stream.listen(
      onProgress == null
          ? (List<int> d) => bytes.addAll(d)
          : (List<int> d) {
              bytes.addAll(d);
              onProgress(bytes.length, stream.contentLength);
            },
      onDone: () => completer.complete(Uint8List.fromList(bytes)),
    );

    var response = Response.bytes(
      await completer.future,
      stream.statusCode,
      request: stream.request,
      headers: stream.headers,
      isRedirect: stream.isRedirect,
      persistentConnection: stream.persistentConnection,
      reasonPhrase: stream.reasonPhrase,
    );

    var responseData = ResponseData.fromHttpResponse(response);
    for (var it in interceptors) {
      responseData = await it.interceptResponse(data: responseData);
    }

    return responseData.toHttpResponse();
  }

  void _checkResponseSuccess(url, Response response) {
    if (response.statusCode < 400) return;
    var message = "Request to $url failed with status ${response.statusCode}";
    if (response.reasonPhrase != null) {
      message = "$message: ${response.reasonPhrase}";
    }
    if (url is String) url = Uri.parse(url);
    throw new ClientException("$message.", url);
  }

  _createRequest({
    Method method,
    Uri url,
    Map<String, String> headers,
    Map<String, dynamic /*String|Iterable<String>*/ > params,
    dynamic body,
    Encoding encoding,
    List<MultipartFile> files,
    Function(int bytes, int total) onUploadProgress,
  }) {
    var request;
    if (files == null) {
      request = Request(methodToString(method), url);
      if (headers != null) request.headers.addAll(headers);
      if (encoding != null) request.encoding = encoding;
      if (body != null) {
        if (body is String) {
          request.body = body;
        } else if (body is List) {
          request.bodyBytes = body.cast<int>();
        } else if (body is Map) {
          request.bodyFields = body.cast<String, String>();
        } else {
          throw new ArgumentError('Invalid request body "$body".');
        }
      }
    } else {
      request =
          MR(methodToString(method), url, onUploadProgress: onUploadProgress);
      if (headers != null) request.headers.addAll(headers);
      if (body != null) request.fields.addAll(body);
      if (files != null) request.files.addAll(files);
    }
    return request;
  }

  void close() {
    _client.close();
  }
}
