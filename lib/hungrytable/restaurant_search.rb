module Hungrytable
  class RestaurantSearch
    include RequestExtensions

    attr_reader :restaurant, :opts

    def initialize restaurant, opts={}
      @opts = opts
      ensure_required_opts
      @requester  = opts[:requester] || GetRequest
      @restaurant = restaurant
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

    def party_size
      opts[:party_size]
    end

    private
    def required_opts
      %w(date_time party_size).map(&:to_sym)
    end

    def encoded_date_time
      URI.encode(opts[:date_time].strftime("%m/%d/%Y %I:%M %p"), /[^a-z0-9\-\.\_\~]/i)
    end

    def request_uri
      "/table/?pid=#{Config.partner_id}&rid=#{restaurant.id}&dt=#{encoded_date_time}&ps=#{party_size}"
    end

    def details
      request.parsed_response["SearchResults"]
    end

  end
end
