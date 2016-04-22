local cjson = require "cjson.safe"

local _M = {
	_VERSION = '0.1.0',
}

local _error_to_http_code = {

  UrlError = ngx.HTTP_NOT_FOUND,
  GroupNotFound = ngx.HTTP_NOT_FOUND,

  MethodError = ngx.HTTP_NOT_ALLOWED,

	Expired = ngx.HTTP_FORBIDDEN,
  SignatureDoesNotMatch = ngx.HTTP_FORBIDDEN,
  ChecksumNotMatch = ngx.HTTP_FORBIDDEN,

  LackOfSsig = ngx.HTTP_BAD_REQUEST,
  InvalidRequest = ngx.HTTP_BAD_REQUEST,

  SystemError = ngx.HTTP_INTERNAL_SERVER_ERROR,
  FileError = ngx.HTTP_INTERNAL_SERVER_ERROR,
  InvalidTmpFileName = ngx.HTTP_INTERNAL_SERVER_ERROR,
	InternalServerError = ngx.HTTP_INTERNAL_SERVER_ERROR,
	GatewayTimeout = ngx.HTTP_GATEWAY_TIMEOUT,

	-- AWS

	AccessDenied = ngx.HTTP_FORBIDDEN,
	AccountProblem = ngx.HTTP_FORBIDDEN,
	BadDigest = ngx.HTTP_BAD_REQUES,
	EntityTooSmall = ngx.HTTP_BAD_REQUES,
	EntityTooLarge = ngx.HTTP_BAD_REQUES,
	ExpiredToken = ngx.HTTP_BAD_REQUES,
	InlineDataTooLarge = ngx.HTTP_BAD_REQUES,
	InternalError = ngx.HTTP_INTERNAL_SERVER_ERROR,
	InvalidAccessKeyId = ngx.HTTP_FORBIDDEN,
	InvalidArgument = ngx.HTTP_BAD_REQUES,
	InvalidBucketName = ngx.HTTP_BAD_REQUES,
	InvalidDigest = ngx.HTTP_BAD_REQUES,
	InvalidToken = ngx.HTTP_BAD_REQUES,
	InvalidURI = ngx.HTTP_BAD_REQUES,
	KeyTooLong = ngx.HTTP_BAD_REQUES,
	MetadataTooLarge = ngx.HTTP_BAD_REQUES,
	MethodNotAllowed = ngx.HTTP_NOT_ALLOWED,
	NoSuchBucket = ngx.HTTP_NOT_FOUND,
	NoSuchKey = ngx.HTTP_NOT_FOUND,
	NoSuchUpload = ngx.HTTP_NOT_FOUND,
	RequestTimeout = ngx.HTTP_BAD_REQUES,
	RequestTimeTooSkewed = ngx.HTTP_FORBIDDEN,
	SignatureDoesNotMatch = ngx.HTTP_FORBIDDEN,
	SlowDown = ngx.HTTP_SERVICE_UNAVAILABLE,
	InvalidFileType = ngx.HTTP_BAD_REQUES,
	UnknownTransformation = ngx.HTTP_BAD_REQUES,
	InvalidTransformation = ngx.HTTP_BAD_REQUES,
}

local _error_to_message = {
	InternalServerError = "Internal Server Error",
	GatewayTimeout = "Gateway Timeout",
	AccessDenied = "Access Denied",
	AccountProblem = "There is a problem with your SCS account that prevents the operation from completing successfully. Please contact customer service at scs_mail@sina.com.",
	BadDigest = "The Content-MD5 you specified did not match what we received.",
	EntityTooSmall = "Your proposed upload is smaller than the minimum allowed object size.",
	EntityTooLarge = "Your proposed upload exceeds the maximum allowed object size.",
	ExpiredToken = "The provided token has expired.",
	InlineDataTooLarge = "Inline data exceeds the maximum allowed size.",
	InternalError = "We encountered an internal error. Please try again.",
	InvalidAccessKeyId = "The SCS Access Key Id you provided does not exist in our records.",
	InvalidArgument = "Invalid Argument",
	InvalidBucketName = "The specified bucket is not valid.",
	InvalidDigest = "The Content-MD5 you specified was an invalid.",
	InvalidToken = "The provided token is malformed or otherwise invalid.",
	InvalidURI = "Couldn't parse the specified URI.",
	KeyTooLong = "Your key is too long.",
	MetadataTooLarge = "Your metadata headers exceed the maximum allowed metadata size.",
	MethodNotAllowed = "The specified method is not allowed against this resource.",
	NoSuchBucket = "The specified bucket does not exist.",
	NoSuchKey = "The specified key does not exist.",
	NoSuchUpload = "The specified multipart upload does not exist. The upload ID might be invalid, or the multipart upload might have been aborted or completed.",
	RequestTimeout = "Your socket connection to the server was not read from or written to within the timeout period.",
	RequestTimeTooSkewed = "The difference between the request time and the server's time is too large.",
	SignatureDoesNotMatch = "The request signature we calculated does not match the signature you provided. Check your SCS Secret Access Key and signing method. For more information, see Authenticating REST Requests and Authenticating SOAP Requests for details.",
	SlowDown = "Please reduce your request rate.",
	InvalidFileType = "Not allowed file type, must be image files.",
	UnknownTransformation = "Unknown Transformation",
	InvalidTransformation = "Invalid Transformation",
}

function _M.err_exit(code, msg)
	if not code then
		code = 'InvalidRequest'
	end
	local err = {
		Error = {
			Message = msg or _error_to_message[code] or (code .. "()"),
			Code = code,
			Resource = ngx.var.raw_uri,
			RequestId = ngx.var.requestid
		}
	}
	local out = cjson.encode(err.Error)
	ngx.status = _error_to_http_code[code] or ngx.HTTP_BAD_REQUEST
	ngx.header["Content-Type"] = "application/json"
	ngx.header["x-error-code"] = code
  ngx.say(out)
  ngx.eof()
  ngx.exit(ngx.HTTP_OK)
end


return _M
