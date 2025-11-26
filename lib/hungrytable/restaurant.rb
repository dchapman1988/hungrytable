# frozen_string_literal: true

module Hungrytable
  # Represents a restaurant and its details from the OpenTable API
  class Restaurant
    include RequestExtensions

    # Attributes that map directly to API response fields
    ATTRIBUTES = %i[
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
    ].freeze

    attr_reader :restaurant_id

    def initialize(restaurant_id, opts = {})
      @requester = opts[:requester] || GetRequest
      @restaurant_id = restaurant_id
    end

    # Alias for consistency
    def id
      @restaurant_id
    end

    # Check if the restaurant query was valid
    # @return [Boolean] true if no errors
    def valid?
      error_ID == '0'
    end

    # Dynamically define getter methods for all attributes
    ATTRIBUTES.each do |attr|
      define_method(attr) do
        # Convert Ruby snake_case to API camelCase, handling special case of ID
        api_key = "ns:#{attr.to_s.camelize.gsub('Id', 'ID')}"
        details[api_key]
      end
    end

    private

    def request_uri
      "/restaurant/?pid=#{Config.partner_id}&rid=#{id}"
    end

    # @return [Hash] restaurant details from API response
    def details
      @details ||= request.parsed_response['RestaurantDetailsResults'] || {}
    end
  end
end
