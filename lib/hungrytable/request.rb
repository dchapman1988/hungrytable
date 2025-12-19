# frozen_string_literal: true

module Hungrytable
  # Base class for API requests
  class Request
    attr_reader :uri, :params

    def initialize(uri, params = {})
      @uri = "#{Hungrytable::Config.base_url}#{uri}" # Fixed: don't mutate base_url
      @params = params
    end

    # Parse the JSON response
    # @return [Hash] parsed JSON response
    # @raise [Hungrytable::HTTPError] if the response is invalid
    def parsed_response
      JSON.parse(response_body)
    rescue JSON::ParserError => e
      raise HTTPError, "Failed to parse response: #{e.message}"
    end

    private

    # Get the response body from the HTTP request
    # @return [String] response body
    def response_body
      @response_body ||= make_request
    end

    # Make the HTTP request (to be implemented by subclasses)
    # @return [String] response body
    def make_request
      raise NotImplementedError, 'Subclasses must implement make_request'
    end

    # Handle HTTP errors
    # @param response [HTTP::Response] the HTTP response object
    # @raise [Hungrytable::HTTPError] if the response indicates an error
    def handle_http_errors(response)
      case response.status.code
      when 200..299
        response.body.to_s
      when 401
        raise UnauthorizedError, 'Authentication failed. Check your OAuth credentials.'
      when 404
        raise NotFoundError, "Resource not found: #{uri}"
      when 500..599
        raise ServerError, "OpenTable server error (#{response.status.code})"
      else
        raise HTTPError, "HTTP error #{response.status.code}: #{response.body}"
      end
    end
  end
end
