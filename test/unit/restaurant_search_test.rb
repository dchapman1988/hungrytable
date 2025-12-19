# frozen_string_literal: true

require 'test_helper'

class RestaurantSearchTest < Minitest::Test
  def setup
    setup_config
    @restaurant = Hungrytable::Restaurant.new(12_345)
    @search_time = Time.parse('2025-02-01 19:00:00')
    @opts = {
      date_time: @search_time,
      party_size: 4
    }
  end

  def teardown
    teardown_config
    WebMock.reset!
  end

  # Initialization tests
  def test_initialization_with_restaurant_and_options
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal @restaurant, search.restaurant
    assert_equal @opts, search.opts
  end

  def test_initialization_raises_error_when_date_time_missing
    opts = { party_size: 4 }

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::RestaurantSearch.new(@restaurant, opts)
    end

    assert_includes error.message, 'date_time'
  end

  def test_initialization_raises_error_when_party_size_missing
    opts = { date_time: @search_time }

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::RestaurantSearch.new(@restaurant, opts)
    end

    assert_includes error.message, 'party_size'
  end

  def test_initialization_raises_error_when_all_required_fields_missing
    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::RestaurantSearch.new(@restaurant, {})
    end

    assert_includes error.message, 'date_time'
    assert_includes error.message, 'party_size'
  end

  # Valid? method tests
  def test_valid_returns_true_when_error_id_is_zero
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_predicate search, :valid?
  end

  def test_valid_returns_false_when_error_id_is_not_zero
    stub_failed_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    refute_predicate search, :valid?
  end

  # Attribute accessor tests
  def test_early_time_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal '2025-02-01 18:30:00', search.early_time
  end

  def test_exact_time_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal '2025-02-01 19:00:00', search.exact_time
  end

  def test_later_time_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal '2025-02-01 19:30:00', search.later_time
  end

  def test_early_security_id_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'early_sec_123', search.early_security_ID
  end

  def test_exact_security_id_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'exact_sec_456', search.exact_security_ID
  end

  def test_later_security_id_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'later_sec_789', search.later_security_ID
  end

  def test_restaurant_name_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'Test Restaurant', search.restaurant_name
  end

  def test_cuisine_type_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'Italian', search.cuisine_type
  end

  def test_error_message_accessor
    stub_failed_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'No availability found', search.error_message
  end

  def test_no_times_message_accessor
    stub_no_times_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'Sorry, no times available for your party', search.no_times_message
  end

  def test_results_key_accessor
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'results_key_abc123', search.results_key
  end

  # ideal_security_id method tests
  def test_ideal_security_id_returns_exact_when_available
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'exact_sec_456', search.ideal_security_id
  end

  def test_ideal_security_id_returns_early_when_exact_not_available
    stub_search_response_with_only_early
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'early_sec_123', search.ideal_security_id
  end

  def test_ideal_security_id_returns_later_when_exact_and_early_not_available
    stub_search_response_with_only_later
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 'later_sec_789', search.ideal_security_id
  end

  def test_ideal_security_id_returns_nil_when_no_times_available
    stub_no_times_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_nil search.ideal_security_id
  end

  # ideal_time method tests
  def test_ideal_time_returns_exact_when_available
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal '2025-02-01 19:00:00', search.ideal_time
  end

  def test_ideal_time_returns_early_when_exact_not_available
    stub_search_response_with_only_early
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal '2025-02-01 18:30:00', search.ideal_time
  end

  def test_ideal_time_returns_later_when_exact_and_early_not_available
    stub_search_response_with_only_later
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal '2025-02-01 19:30:00', search.ideal_time
  end

  def test_ideal_time_returns_nil_when_no_times_available
    stub_no_times_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_nil search.ideal_time
  end

  # party_size method tests
  def test_party_size_returns_correct_value
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_equal 4, search.party_size
  end

  def test_party_size_returns_different_sizes
    opts = @opts.merge(party_size: 8)
    search = Hungrytable::RestaurantSearch.new(@restaurant, opts)

    assert_equal 8, search.party_size
  end

  # Request URI tests
  def test_request_uri_includes_partner_id
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)
    uri = search.send(:request_uri)

    assert_includes uri, 'pid=test_partner_id'
  end

  def test_request_uri_includes_restaurant_id
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)
    uri = search.send(:request_uri)

    assert_includes uri, 'rid=12345'
  end

  def test_request_uri_includes_encoded_date_time
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)
    uri = search.send(:request_uri)

    # Check that the date is properly encoded
    assert_includes uri, 'dt='
    assert_includes uri, '02%2F01%2F2025'
  end

  def test_request_uri_includes_party_size
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)
    uri = search.send(:request_uri)

    assert_includes uri, 'ps=4'
  end

  # Integration tests with WebMock
  def test_handles_api_response_correctly
    stub_successful_search_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    assert_predicate search, :valid?
    assert_equal 'Test Restaurant', search.restaurant_name
    assert_equal 'exact_sec_456', search.exact_security_ID
  end

  def test_handles_no_availability_response
    stub_no_times_response
    search = Hungrytable::RestaurantSearch.new(@restaurant, @opts)

    refute_predicate search, :valid?
    assert_nil search.ideal_security_id
    assert_nil search.ideal_time
  end

  private

  def stub_successful_search_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/table/})
      .to_return(
        status: 200,
        body: successful_search_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_failed_search_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/table/})
      .to_return(
        status: 200,
        body: failed_search_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_no_times_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/table/})
      .to_return(
        status: 200,
        body: no_times_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_search_response_with_only_early
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/table/})
      .to_return(
        status: 200,
        body: only_early_time_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_search_response_with_only_later
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/table/})
      .to_return(
        status: 200,
        body: only_later_time_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def successful_search_json
    {
      SearchResults: {
        'ns:ErrorID' => '0',
        'ns:RestaurantName' => 'Test Restaurant',
        'ns:CuisineType' => 'Italian',
        'ns:EarlyTime' => '2025-02-01 18:30:00',
        'ns:EarlySecurityID' => 'early_sec_123',
        'ns:ExactTime' => '2025-02-01 19:00:00',
        'ns:ExactSecurityID' => 'exact_sec_456',
        'ns:LaterTime' => '2025-02-01 19:30:00',
        'ns:LaterSecurityID' => 'later_sec_789',
        'ns:ResultsKey' => 'results_key_abc123',
        'ns:Latitude' => '40.7589',
        'ns:Longitude' => '-73.9851',
        'ns:NeighborhoodName' => 'Midtown'
      }
    }.to_json
  end

  def failed_search_json
    {
      SearchResults: {
        'ns:ErrorID' => '1',
        'ns:ErrorMessage' => 'No availability found'
      }
    }.to_json
  end

  def no_times_json
    {
      SearchResults: {
        'ns:ErrorID' => '2',
        'ns:NoTimesMessage' => 'Sorry, no times available for your party',
        'ns:RestaurantName' => 'Test Restaurant'
      }
    }.to_json
  end

  def only_early_time_json
    {
      SearchResults: {
        'ns:ErrorID' => '0',
        'ns:RestaurantName' => 'Test Restaurant',
        'ns:EarlyTime' => '2025-02-01 18:30:00',
        'ns:EarlySecurityID' => 'early_sec_123',
        'ns:ResultsKey' => 'results_key_abc123'
      }
    }.to_json
  end

  def only_later_time_json
    {
      SearchResults: {
        'ns:ErrorID' => '0',
        'ns:RestaurantName' => 'Test Restaurant',
        'ns:LaterTime' => '2025-02-01 19:30:00',
        'ns:LaterSecurityID' => 'later_sec_789',
        'ns:ResultsKey' => 'results_key_abc123'
      }
    }.to_json
  end
end
