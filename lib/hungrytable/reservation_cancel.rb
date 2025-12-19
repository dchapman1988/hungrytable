# frozen_string_literal: true

module Hungrytable
  # Cancels an existing restaurant reservation
  class ReservationCancel
    include RequestExtensions

    attr_reader :opts

    def initialize(opts = {})
      @opts = opts
      ensure_required_opts
      @requester = opts[:requester] || GetRequest
    end

    # Check if the cancellation was successful
    # @return [Boolean] true if no errors
    def successful?
      details['ns:ErrorID'].to_s == '0'
    end

    # Get error messages if cancellation failed
    # @return [String, nil] error message or nil
    def error_message
      details['ns:ErrorMessage']
    end

    private

    def request_uri
      "/reservation/?pid=#{Config.partner_id}&rid=#{opts[:restaurant_id]}&" \
        "conf=#{CGI.escape(opts[:confirmation_number].to_s)}&email=#{CGI.escape(opts[:email_address])}"
    end

    # @return [Hash] cancellation results from API response
    def details
      @details ||= request.parsed_response['Results'] || {}
    end

    def required_opts
      %i[email_address confirmation_number restaurant_id]
    end
  end
end
