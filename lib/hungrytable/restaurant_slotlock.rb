module Hungrytable
  class RestaurantSlotlock

    attr_reader :restaurant_search

    def initialize restaurant_search, opts={}
      @restaurant_search = restaurant_search
      handle_initial_request
    end

    def successful?
      details["ns:ErrorID"] == "0"
    end

    def slotlock_id
      return nil unless successful?
      details["ns:SlotLockID"]
    end

    def handle_initial_request
      @initial_request = PostRequest.new("/slotlock/?pid=#{Config.partner_id}&st=0", params)
    end

    def restaurant
      restaurant_search.restaurant
    end

    def details
      @initial_request.parsed_response["SlotLockResults"]
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
  end
end
