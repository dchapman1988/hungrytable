# frozen_string_literal: true

module Hungrytable
  # Base error class for all Hungrytable errors
  class Error < StandardError; end

  # Configuration errors
  class ConfigurationError < Error; end

  # API errors
  class APIError < Error
    attr_reader :error_code, :error_message

    def initialize(error_code, error_message)
      @error_code = error_code
      @error_message = error_message
      super("OpenTable API Error #{error_code}: #{error_message}")
    end
  end

  # HTTP errors
  class HTTPError < Error; end
  class NotFoundError < HTTPError; end
  class UnauthorizedError < HTTPError; end
  class ServerError < HTTPError; end

  # Validation errors
  class ValidationError < Error; end
  class MissingRequiredFieldError < ValidationError; end

  # OpenTable specific errors mapped from error codes
  class ReservationError < APIError; end
  class SlotlockError < APIError; end
  class RestaurantNotFoundError < APIError; end
  class NoAvailabilityError < APIError; end
end
