# frozen_string_literal: true

module Hungrytable
  # Searches for available reservation times at a restaurant
  class RestaurantSearch
    include RequestExtensions

    # Attributes that map directly to API response fields
    ATTRIBUTES = %i[
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
      no_times_message
    ].freeze

    attr_reader :restaurant, :opts

    def initialize(restaurant, opts = {})
      @opts = opts
      ensure_required_opts
      validate_date_time_type
      validate_party_size
      @requester = opts[:requester] || GetRequest
      @restaurant = restaurant
    end

    # Check if the search was valid
    # @return [Boolean] true if no errors
    def valid?
      error_ID.to_s == '0'
    end

    # Dynamically define getter methods for all attributes
    ATTRIBUTES.each do |attr|
      define_method(attr) do
        # Convert Ruby snake_case to API camelCase, handling special case of ID
        api_key = "ns:#{attr.to_s.camelize.gsub('Id', 'ID')}"
        details[api_key]
      end
    end

    # Get the best available security ID
    # @return [String, nil] the ideal security ID for slotlock
    def ideal_security_id
      exact_security_ID || early_security_ID || later_security_ID
    end

    # Get the best available time
    # @return [String, nil] the ideal time for reservation
    def ideal_time
      exact_time || early_time || later_time
    end

    # Get the party size for this search
    # @return [Integer] number of people
    def party_size
      opts[:party_size]
    end

    private

    def required_opts
      %i[date_time party_size]
    end

    def encoded_date_time
      # Use CGI.escape instead of deprecated URI.encode
      CGI.escape(opts[:date_time].strftime('%m/%d/%Y %I:%M %p'))
    end

    def request_uri
      "/table/?pid=#{Config.partner_id}&rid=#{restaurant.id}&dt=#{encoded_date_time}&ps=#{party_size}"
    end

    # @return [Hash] search results from API response
    def details
      @details ||= request.parsed_response['SearchResults'] || {}
    end

    def validate_date_time_type
      return if opts[:date_time].respond_to?(:strftime)

      raise ValidationError,
            "date_time must be a Time or DateTime object, got #{opts[:date_time].class}"
    end

    def validate_party_size
      ps = opts[:party_size]
      return if ps.is_a?(Integer) && ps.positive? && ps <= 20

      raise ValidationError,
            "party_size must be a positive integer between 1 and 20, got #{ps.inspect}"
    end
  end
end
