# frozen_string_literal: true

module Hungrytable
  # Locks a reservation time slot before making a reservation
  class RestaurantSlotlock
    include RequestExtensions

    attr_reader :restaurant_search

    def initialize(restaurant_search, requester = PostRequest)
      @restaurant_search = restaurant_search
      @requester = requester
      validate_search_has_results
    end

    # Check if the slotlock was successful
    # @return [Boolean] true if no errors
    def successful?
      details['ns:ErrorID'].to_s == '0'
    end

    # Get error messages if slotlock failed
    # @return [String, nil] error message or nil
    def errors
      details['ns:ErrorMessage']
    end

    # Get the slotlock ID needed for making a reservation
    # @return [String, nil] slotlock ID or nil if unsuccessful
    def slotlock_id
      return nil unless successful?

      details['ns:SlotLockID']
    end

    # Parameters to send with the slotlock request
    # @return [Hash] request parameters
    def params
      {
        'RID' => restaurant.id,
        'datetime' => restaurant_search.ideal_time,
        'partysize' => restaurant_search.party_size,
        'timesecurityID' => restaurant_search.ideal_security_id,
        'resultskey' => restaurant_search.results_key
      }
    end

    private

    def request_uri
      "/slotlock/?pid=#{Config.partner_id}&st=0"
    end

    def restaurant
      restaurant_search.restaurant
    end

    # @return [Hash] slotlock results from API response
    def details
      @details ||= request.parsed_response['SlotLockResults'] || {}
    end

    def validate_search_has_results
      if restaurant_search.ideal_security_id.nil? ||
         restaurant_search.ideal_time.nil? ||
         restaurant_search.results_key.nil?
        raise ValidationError, 'Cannot create slotlock: no available times found in restaurant search'
      end
    end
  end
end
