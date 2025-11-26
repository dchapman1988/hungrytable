# frozen_string_literal: true

require 'test_helper'

class RestaurantSlotlockTest < Minitest::Test
  def setup
    setup_config
    @restaurant = Hungrytable::Restaurant.new(12_345)
    @search_time = Time.parse('2025-02-01 19:00:00')

    # Create a mock restaurant search
    @restaurant_search = Minitest::Mock.new
    @restaurant_search.expect :restaurant, @restaurant
    @restaurant_search.expect :ideal_time, '2025-02-01 19:00:00'
    @restaurant_search.expect :party_size, 4
    @restaurant_search.expect :ideal_security_id, 'exact_sec_456'
    @restaurant_search.expect :results_key, 'results_key_abc123'
  end

  def teardown
    teardown_config
    WebMock.reset!
  end

  # Initialization tests
  def test_initialization_with_restaurant_search
    # Use a simple stub instead of mock to avoid strict method checking in initialization
    stub_search = Object.new
    slotlock = Hungrytable::RestaurantSlotlock.new(stub_search)

    assert_equal stub_search, slotlock.restaurant_search
  end

  def test_initialization_accepts_custom_requester
    # Don't verify mock since we don't actually call the requester in initialization
    stub_search = Object.new
    stub_requester = Object.new
    slotlock = Hungrytable::RestaurantSlotlock.new(stub_search, stub_requester)

    assert_equal stub_search, slotlock.restaurant_search
  end

  # successful? method tests
  def test_successful_returns_true_when_error_id_is_zero
    stub_successful_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    assert_predicate slotlock, :successful?
  end

  def test_successful_returns_false_when_error_id_is_not_zero
    stub_failed_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    refute_predicate slotlock, :successful?
  end

  # slotlock_id method tests
  def test_slotlock_id_returns_id_when_successful
    stub_successful_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    assert_equal 'slotlock_xyz789', slotlock.slotlock_id
  end

  def test_slotlock_id_returns_nil_when_unsuccessful
    stub_failed_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    assert_nil slotlock.slotlock_id
  end

  def test_slotlock_id_returns_nil_when_api_error
    stub_api_error_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    assert_nil slotlock.slotlock_id
  end

  # errors method tests
  def test_errors_returns_nil_when_successful
    stub_successful_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    assert_nil slotlock.errors
  end

  def test_errors_returns_message_when_unsuccessful
    stub_failed_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    assert_equal 'Time slot no longer available', slotlock.errors
  end

  def test_errors_returns_message_when_invalid_request
    stub_invalid_request_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    assert_equal 'Invalid party size', slotlock.errors
  end

  # params method tests
  def test_params_builds_correct_hash
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)
    params = slotlock.params

    assert_equal 12_345, params['RID']
    assert_equal '2025-02-01 19:00:00', params['datetime']
    assert_equal 4, params['partysize']
    assert_equal 'exact_sec_456', params['timesecurityID']
    assert_equal 'results_key_abc123', params['resultskey']
  end

  def test_params_uses_restaurant_search_data
    # Create a different mock with different values
    different_search = Minitest::Mock.new
    different_restaurant = Hungrytable::Restaurant.new(99_999)

    different_search.expect :restaurant, different_restaurant
    different_search.expect :ideal_time, '2025-03-15 20:00:00'
    different_search.expect :party_size, 6
    different_search.expect :ideal_security_id, 'different_sec_999'
    different_search.expect :results_key, 'different_key_xyz'

    slotlock = Hungrytable::RestaurantSlotlock.new(different_search)
    params = slotlock.params

    assert_equal 99_999, params['RID']
    assert_equal '2025-03-15 20:00:00', params['datetime']
    assert_equal 6, params['partysize']
    assert_equal 'different_sec_999', params['timesecurityID']
    assert_equal 'different_key_xyz', params['resultskey']

    different_search.verify
  end

  # Request URI tests
  def test_request_uri_includes_partner_id
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)
    uri = slotlock.send(:request_uri)

    assert_includes uri, 'pid=test_partner_id'
  end

  def test_request_uri_includes_st_parameter
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)
    uri = slotlock.send(:request_uri)

    assert_includes uri, 'st=0'
  end

  def test_request_uri_format
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)
    uri = slotlock.send(:request_uri)

    assert_equal '/slotlock/?pid=test_partner_id&st=0', uri
  end

  # Integration tests with WebMock
  def test_handles_successful_api_response_correctly
    stub_successful_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    assert_predicate slotlock, :successful?
    assert_equal 'slotlock_xyz789', slotlock.slotlock_id
    assert_nil slotlock.errors
  end

  def test_handles_failed_api_response_correctly
    stub_failed_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    refute_predicate slotlock, :successful?
    assert_nil slotlock.slotlock_id
    assert_equal 'Time slot no longer available', slotlock.errors
  end

  def test_handles_api_error_response
    stub_api_error_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    refute_predicate slotlock, :successful?
    assert_nil slotlock.slotlock_id
  end

  # Edge case tests
  def test_handles_empty_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/slotlock/})
      .to_return(
        status: 200,
        body: { SlotLockResults: {} }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    refute_predicate slotlock, :successful?
    assert_nil slotlock.slotlock_id
  end

  def test_handles_missing_slotlock_results_key
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/slotlock/})
      .to_return(
        status: 200,
        body: {}.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    slotlock = Hungrytable::RestaurantSlotlock.new(@restaurant_search)

    # Should not raise an error, just return nil values
    refute_predicate slotlock, :successful?
    assert_nil slotlock.slotlock_id
  end

  private

  def stub_successful_slotlock_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/slotlock/})
      .to_return(
        status: 200,
        body: successful_slotlock_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_failed_slotlock_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/slotlock/})
      .to_return(
        status: 200,
        body: failed_slotlock_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_api_error_slotlock_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/slotlock/})
      .to_return(
        status: 200,
        body: api_error_slotlock_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_invalid_request_slotlock_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/slotlock/})
      .to_return(
        status: 200,
        body: invalid_request_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def successful_slotlock_json
    {
      SlotLockResults: {
        'ns:ErrorID' => '0',
        'ns:SlotLockID' => 'slotlock_xyz789'
      }
    }.to_json
  end

  def failed_slotlock_json
    {
      SlotLockResults: {
        'ns:ErrorID' => '1',
        'ns:ErrorMessage' => 'Time slot no longer available'
      }
    }.to_json
  end

  def api_error_slotlock_json
    {
      SlotLockResults: {
        'ns:ErrorID' => '500',
        'ns:ErrorMessage' => 'Internal server error'
      }
    }.to_json
  end

  def invalid_request_json
    {
      SlotLockResults: {
        'ns:ErrorID' => '2',
        'ns:ErrorMessage' => 'Invalid party size'
      }
    }.to_json
  end
end
