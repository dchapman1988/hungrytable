# frozen_string_literal: true

require 'test_helper'

class RestaurantSlotlockTest < Minitest::Test
  def setup
    setup_config
    @restaurant = Hungrytable::Restaurant.new(12_345)
    @search_time = Time.parse('2025-02-01 19:00:00')
  end

  # Helper to create a restaurant search mock with expectations for validation
  def create_restaurant_search_mock
    mock = Minitest::Mock.new
    # Expectations for validation during initialization
    mock.expect :ideal_security_id, 'exact_sec_456'
    mock.expect :ideal_time, '2025-02-01 19:00:00'
    mock.expect :results_key, 'results_key_abc123'
    # Additional expectations for params method
    mock.expect :restaurant, @restaurant
    mock.expect :ideal_time, '2025-02-01 19:00:00'
    mock.expect :party_size, 4
    mock.expect :ideal_security_id, 'exact_sec_456'
    mock.expect :results_key, 'results_key_abc123'
    mock
  end

  def teardown
    teardown_config
    WebMock.reset!
  end

  # Initialization tests
  def test_initialization_with_restaurant_search
    # Create a minimal stub that responds to validation methods
    stub_search = Minitest::Mock.new
    stub_search.expect :ideal_security_id, 'some_id'
    stub_search.expect :ideal_time, 'some_time'
    stub_search.expect :results_key, 'some_key'

    slotlock = Hungrytable::RestaurantSlotlock.new(stub_search)

    # Verify validation methods were called (this confirms initialization worked)
    stub_search.verify

    assert_instance_of Hungrytable::RestaurantSlotlock, slotlock
  end

  def test_initialization_accepts_custom_requester
    # Create a stub that responds to validation methods
    stub_search = Minitest::Mock.new
    stub_search.expect :ideal_security_id, 'some_id'
    stub_search.expect :ideal_time, 'some_time'
    stub_search.expect :results_key, 'some_key'

    stub_requester = Object.new
    slotlock = Hungrytable::RestaurantSlotlock.new(stub_search, stub_requester)

    # Verify validation methods were called (this confirms initialization worked)
    stub_search.verify

    assert_instance_of Hungrytable::RestaurantSlotlock, slotlock
  end

  def test_initialization_raises_error_when_no_available_times
    search = Minitest::Mock.new
    search.expect :ideal_security_id, nil
    search.expect :ideal_time, nil
    search.expect :results_key, nil

    error = assert_raises(Hungrytable::ValidationError) do
      Hungrytable::RestaurantSlotlock.new(search)
    end

    assert_match(/no available times found/, error.message)
  end

  # successful? method tests
  def test_successful_returns_true_when_error_id_is_zero
    stub_successful_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    assert_predicate slotlock, :successful?
  end

  def test_successful_returns_false_when_error_id_is_not_zero
    stub_failed_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    refute_predicate slotlock, :successful?
  end

  # slotlock_id method tests
  def test_slotlock_id_returns_id_when_successful
    stub_successful_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    assert_equal 'slotlock_xyz789', slotlock.slotlock_id
  end

  def test_slotlock_id_returns_nil_when_unsuccessful
    stub_failed_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    assert_nil slotlock.slotlock_id
  end

  def test_slotlock_id_returns_nil_when_api_error
    stub_api_error_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    assert_nil slotlock.slotlock_id
  end

  # errors method tests
  def test_errors_returns_nil_when_successful
    stub_successful_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    assert_nil slotlock.errors
  end

  def test_errors_returns_message_when_unsuccessful
    stub_failed_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    assert_equal 'Time slot no longer available', slotlock.errors
  end

  def test_errors_returns_message_when_invalid_request
    stub_invalid_request_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    assert_equal 'Invalid party size', slotlock.errors
  end

  # params method tests
  def test_params_builds_correct_hash
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)
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

    # Expectations for validation during initialization
    different_search.expect :ideal_security_id, 'different_sec_999'
    different_search.expect :ideal_time, '2025-03-15 20:00:00'
    different_search.expect :results_key, 'different_key_xyz'
    # Additional expectations for params method
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
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)
    uri = slotlock.send(:request_uri)

    assert_includes uri, 'pid=test_partner_id'
  end

  def test_request_uri_includes_st_parameter
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)
    uri = slotlock.send(:request_uri)

    assert_includes uri, 'st=0'
  end

  def test_request_uri_format
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)
    uri = slotlock.send(:request_uri)

    assert_equal '/slotlock/?pid=test_partner_id&st=0', uri
  end

  # Integration tests with WebMock
  def test_handles_successful_api_response_correctly
    stub_successful_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    assert_predicate slotlock, :successful?
    assert_equal 'slotlock_xyz789', slotlock.slotlock_id
    assert_nil slotlock.errors
  end

  def test_handles_failed_api_response_correctly
    stub_failed_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

    refute_predicate slotlock, :successful?
    assert_nil slotlock.slotlock_id
    assert_equal 'Time slot no longer available', slotlock.errors
  end

  def test_handles_api_error_response
    stub_api_error_slotlock_response
    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

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

    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

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

    slotlock = Hungrytable::RestaurantSlotlock.new(create_restaurant_search_mock)

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
