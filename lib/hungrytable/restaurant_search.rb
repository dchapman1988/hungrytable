module Hungrytable
  class RestaurantSearch

    attr_reader :restaurant, :date, :party_size

    def initialize restaurant, options
      raise ArgumentError, "options must include a value for date" unless options.has_key?(:date)
      raise ArgumentError, "options must include a value for party size" unless options.has_key?(:party_size)
      @restaurant = restaurant
      @date       = options[:date]
      @party_size = options[:party_size]
      handle_initial_request
    end

    def valid?
      error_ID == "0"
    end

    def method_missing meth, *args, &blk
      if %w(
            cuisine_type
            early_security_ID
            early_time
            error_ID
            error_message
            exact_security_ID
            exact_time
            later_security_ID
            later_time
            latitude
            longitude
            neighborhood_name
            restaurant_name
            results_key
          ).map(&:to_sym).include?(meth)
        return details["ns:#{meth.to_s.camelize}"]
      end
      super
    end

    def ideal_security_id
      return exact_security_ID unless exact_security_ID.nil?
      return early_security_ID unless early_security_ID.nil?
      return later_security_ID unless later_security_ID.nil?
      nil
    end

    def ideal_time
      return exact_time unless exact_time.nil?
      return early_time unless early_time.nil?
      return later_time unless later_time.nil?
      nil
    end

    private
    def encoded_date
      URI.encode(date.strftime("%m/%d/%Y %I:%M %p"), /[^a-z0-9\-\.\_\~]/i)
    end

    def handle_initial_request
      @initial_request = GetRequest.new("/table/?pid=#{Config.partner_id}&rid=#{restaurant.id}&dt=#{encoded_date}&ps=#{party_size}")
    end

    def details
      @initial_request.parsed_response["SearchResults"]
    end

  end
end
