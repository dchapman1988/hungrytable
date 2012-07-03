require 'test_helper'
require 'pry'

describe Hungrytable::Restaurant do
  before do
    @mock_requester = mock('GetRequest')
    @mock_request   = mock('get')
    @mock_requester.expects(:new).returns(@mock_request)
    @mock_request.stubs(:parsed_response).returns({"RestaurantDetailsResults" => {}})
    ENV['OT_PARTNER_ID']   = 'foo'
    @restaurant = Hungrytable::Restaurant.new(1, requester: @mock_requester)
  end
  %w(
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
    ).map(&:to_sym).each do |meth|
      it "responds to #{meth.to_s} via method_missing" do
        @restaurant.send(meth).must_equal nil
      end
    end
end
