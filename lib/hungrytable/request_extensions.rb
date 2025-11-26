# frozen_string_literal: true

module Hungrytable
  # Shared functionality for classes that make API requests
  # Follows DRY principle - don't repeat yourself
  module RequestExtensions
    extend ActiveSupport::Concern

    private

    # Get the request object (lazy-loaded)
    # @return [Request] the request object
    def request
      @request ||= @requester.new(request_uri, params)
    end

    # Ensure all required options are present
    # @raise [MissingRequiredFieldError] if any required field is missing
    def ensure_required_opts
      return unless respond_to?(:required_opts, true)

      missing = required_opts.reject { |key| opts.key?(key) }
      return if missing.empty?

      raise MissingRequiredFieldError, "Missing required fields: #{missing.join(', ')}"
    end

    # Default params (can be overridden in classes that send POST requests)
    # @return [Hash] request parameters
    def params
      {}
    end
  end
end
