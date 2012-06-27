module Hungrytable
  class Restaurant

    def initialize restaurant_id
      @restaurant_id = restaurant_id
      handle_initial_request
    end

    def id
      @restaurant_id
    end

    def valid?
      error_ID == "0"
    end

    def method_missing meth, *args, &blk
      if %w(
            address
            city
            error_ID
            error_message
            image_link
            latitude
            longitude
            metro_name
            neighborhood_name
            parking
            parking_details
            phone
            postal_code
            price_range
            primary_food_type
            restaurant_description
            restaurant_ID
            restaurant_name
            state
            url
          ).map(&:to_sym).include?(meth)
        return details["ns:#{meth.to_s.camelize}"]
      end
      super
    end


    private
    def handle_initial_request
      @initial_request = GetRequest.new("/restaurant/?pid=#{Config.partner_id}&rid=#{id}")
    end

    # @return [Hash]
    def details
      @initial_request.parsed_response["RestaurantDetailsResults"]
    end

  end
end
