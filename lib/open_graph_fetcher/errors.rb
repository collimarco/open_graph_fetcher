module OpenGraphFetcher
  class Error < StandardError; end

  class InvalidSchemeError < Error; end
  class InvalidPortError < Error; end
  class IPResolutionError < Error; end
  class PrivateIPError < Error; end
  class FetchError < Error; end
  class ResponseError < Error; end
  class InvalidContentTypeError < Error; end
end
