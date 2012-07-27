module Hungrytable
  class RestaurantSlotlock
    include RequestExtensions

    attr_reader :restaurant_search

    def initialize restaurant_search, requester=PostRequest
      @restaurant_search = restaurant_search
      @requester         = requester
    end

    def successful?
      details["ns:ErrorID"] == "0"
    end

    def errors
      details["ns:ErrorMessage"]
    end

    def slotlock_id
      return nil unless successful?
      details["ns:SlotLockID"]
    end

    def params
      {
        'RID'            => restaurant.id,
        'datetime'       => restaurant_search.ideal_time,
        'partysize'      => restaurant_search.party_size,
        'timesecurityID' => restaurant_search.ideal_security_id,
        'resultskey'     => restaurant_search.results_key
      }
    end

    private
    def request_uri
      "/slotlock/?pid=#{Config.partner_id}&st=0"
    end

    def restaurant
      restaurant_search.restaurant
    end

    def details
      request.parsed_response["SlotLockResults"]
    end

  end
end
