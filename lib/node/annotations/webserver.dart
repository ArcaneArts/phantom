class OnRequest {
  final String method;
  final String path;

  const OnRequest._(this.method, this.path);

  const OnRequest.get(this.path) : method = "GET";

  const OnRequest.post(this.path) : method = "POST";

  const OnRequest.put(this.path) : method = "PUT";

  const OnRequest.delete(this.path) : method = "DELETE";

  const OnRequest.patch(this.path) : method = "PATCH";

  const OnRequest.options(this.path) : method = "OPTIONS";
}
