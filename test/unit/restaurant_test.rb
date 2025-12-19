# frozen_string_literal: true

require 'test_helper'

class RestaurantTest < Minitest::Test
  def setup
    setup_config
    @restaurant = Hungrytable::Restaurant.new(12_345)
  end

  def teardown
    teardown_config
  end

  def test_initialization_with_id
    assert_equal 12_345, @restaurant.restaurant_id
    assert_equal 12_345, @restaurant.id
  end

  def test_responds_to_all_attributes
    Hungrytable::Restaurant::ATTRIBUTES.each do |attr|
      assert_respond_to @restaurant, attr
    end
  end

  def test_valid_returns_true_when_error_id_is_zero
    requester_mock = Minitest::Mock.new
    response_mock = Minitest::Mock.new

    requester_mock.expect :new, response_mock, [String, Hash]
    response_mock.expect :parsed_response, { 'RestaurantDetailsResults' => { 'ns:ErrorID' => '0' } }

    restaurant = Hungrytable::Restaurant.new(12_345, requester: requester_mock)

    assert_predicate restaurant, :valid?

    requester_mock.verify
    response_mock.verify
  end

  def test_valid_returns_false_when_error_id_is_not_zero
    requester_mock = Minitest::Mock.new
    response_mock = Minitest::Mock.new

    requester_mock.expect :new, response_mock, [String, Hash]
    response_mock.expect :parsed_response, { 'RestaurantDetailsResults' => { 'ns:ErrorID' => '1' } }

    restaurant = Hungrytable::Restaurant.new(12_345, requester: requester_mock)

    refute_predicate restaurant, :valid?

    requester_mock.verify
    response_mock.verify
  end

  def test_attributes_map_to_api_response
    requester_mock = Minitest::Mock.new
    response_mock = Minitest::Mock.new

    api_response = {
      'RestaurantDetailsResults' => {
        'ns:RestaurantName' => 'Test Restaurant',
        'ns:Address' => '123 Main St',
        'ns:Phone' => '555-1234',
        'ns:ErrorID' => '0'
      }
    }

    requester_mock.expect :new, response_mock, [String, Hash]
    response_mock.expect :parsed_response, api_response

    restaurant = Hungrytable::Restaurant.new(12_345, requester: requester_mock)

    assert_equal 'Test Restaurant', restaurant.restaurant_name
    assert_equal '123 Main St', restaurant.address
    assert_equal '555-1234', restaurant.phone

    requester_mock.verify
    response_mock.verify
  end

  def test_request_uri_includes_partner_id_and_restaurant_id
    uri = @restaurant.send(:request_uri)

    assert_includes uri, 'pid=test_partner_id'
    assert_includes uri, 'rid=12345'
  end
end
