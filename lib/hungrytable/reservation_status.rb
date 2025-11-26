# frozen_string_literal: true

module Hungrytable
  # Checks the status of an existing reservation
  class ReservationStatus
    include RequestExtensions

    attr_reader :opts

    def initialize(opts = {})
      @opts = opts
      ensure_required_opts
      @requester = opts[:requester] || GetRequest
    end

    # @return [Boolean] true if the status request was successful
    def successful?
      details['ns:ErrorID'] == '0'
    end

    # @return [String] the current status of the reservation
    def status
      return nil unless successful?

      details['ns:ReservationStatus']
    end

    # @return [Hash] all reservation details
    def reservation_details
      return nil unless successful?

      {
        status: details['ns:ReservationStatus'],
        restaurant_name: details['ns:RestaurantName'],
        date_time: details['ns:DateTime'],
        party_size: details['ns:PartySize'],
        confirmation_number: opts[:confirmation_number]
      }
    end

    private

    def request_uri
      "/reservationstatus/?pid=#{Config.partner_id}&rid=#{opts[:restaurant_id]}&conf=#{opts[:confirmation_number]}"
    end

    def details
      @details ||= request.parsed_response['StatusResults'] || {}
    end

    def required_opts
      %i[confirmation_number restaurant_id]
    end
  end
end
