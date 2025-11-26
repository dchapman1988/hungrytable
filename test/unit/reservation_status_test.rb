# frozen_string_literal: true

require 'test_helper'

class ReservationStatusTest < Minitest::Test
  def setup
    setup_config
    @valid_opts = {
      confirmation_number: 'CONF123456',
      restaurant_id: 12_345
    }
  end

  def teardown
    teardown_config
    WebMock.reset!
  end

  # Initialization tests
  def test_initialization_with_valid_options
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_equal @valid_opts, status_check.opts
  end

  def test_initialization_raises_error_when_confirmation_number_missing
    opts = @valid_opts.dup
    opts.delete(:confirmation_number)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationStatus.new(opts)
    end

    assert_includes error.message, 'confirmation_number'
  end

  def test_initialization_raises_error_when_restaurant_id_missing
    opts = @valid_opts.dup
    opts.delete(:restaurant_id)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationStatus.new(opts)
    end

    assert_includes error.message, 'restaurant_id'
  end

  def test_initialization_raises_error_when_all_required_fields_missing
    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationStatus.new({})
    end

    assert_includes error.message, 'confirmation_number'
    assert_includes error.message, 'restaurant_id'
  end

  # successful? method tests
  def test_successful_returns_true_when_error_id_is_zero
    stub_successful_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_predicate status_check, :successful?
  end

  def test_successful_returns_false_when_error_id_is_not_zero
    stub_failed_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    refute_predicate status_check, :successful?
  end

  # status method tests
  def test_status_returns_confirmed_when_successful
    stub_successful_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_equal 'Confirmed', status_check.status
  end

  def test_status_returns_nil_when_unsuccessful
    stub_failed_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_nil status_check.status
  end

  def test_status_returns_different_statuses
    stub_cancelled_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_equal 'Cancelled', status_check.status
  end

  def test_status_returns_seated_status
    stub_seated_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_equal 'Seated', status_check.status
  end

  # reservation_details method tests
  def test_reservation_details_returns_complete_hash_when_successful
    stub_successful_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)
    details = status_check.reservation_details

    assert_instance_of Hash, details
    assert_equal 'Confirmed', details[:status]
    assert_equal 'Test Restaurant', details[:restaurant_name]
    assert_equal '2025-02-01 19:00:00', details[:date_time]
    assert_equal '4', details[:party_size]
    assert_equal 'CONF123456', details[:confirmation_number]
  end

  def test_reservation_details_returns_nil_when_unsuccessful
    stub_failed_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_nil status_check.reservation_details
  end

  def test_reservation_details_includes_confirmation_number_from_opts
    stub_successful_status_response
    opts = @valid_opts.merge(confirmation_number: 'CONF999999')
    status_check = Hungrytable::ReservationStatus.new(opts)
    details = status_check.reservation_details

    assert_equal 'CONF999999', details[:confirmation_number]
  end

  def test_reservation_details_contains_all_expected_keys
    stub_successful_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)
    details = status_check.reservation_details

    assert_includes details.keys, :status
    assert_includes details.keys, :restaurant_name
    assert_includes details.keys, :date_time
    assert_includes details.keys, :party_size
    assert_includes details.keys, :confirmation_number
  end

  def test_reservation_details_with_different_party_sizes
    stub_status_response_with_large_party
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)
    details = status_check.reservation_details

    assert_equal '12', details[:party_size]
  end

  # Request URI tests
  def test_request_uri_includes_partner_id
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)
    uri = status_check.send(:request_uri)

    assert_includes uri, 'pid=test_partner_id'
  end

  def test_request_uri_includes_restaurant_id
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)
    uri = status_check.send(:request_uri)

    assert_includes uri, 'rid=12345'
  end

  def test_request_uri_includes_confirmation_number
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)
    uri = status_check.send(:request_uri)

    assert_includes uri, 'conf=CONF123456'
  end

  def test_request_uri_format
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)
    uri = status_check.send(:request_uri)

    expected_uri = '/reservationstatus/?pid=test_partner_id&rid=12345&conf=CONF123456'

    assert_equal expected_uri, uri
  end

  # Integration tests with WebMock
  def test_handles_successful_api_response_correctly
    stub_successful_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_predicate status_check, :successful?
    assert_equal 'Confirmed', status_check.status
    refute_nil status_check.reservation_details
  end

  def test_handles_failed_api_response_correctly
    stub_failed_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    refute_predicate status_check, :successful?
    assert_nil status_check.status
    assert_nil status_check.reservation_details
  end

  def test_handles_cancelled_reservation_response
    stub_cancelled_status_response
    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_predicate status_check, :successful?
    assert_equal 'Cancelled', status_check.status
    details = status_check.reservation_details

    assert_equal 'Cancelled', details[:status]
  end

  # Edge case tests
  def test_handles_empty_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .to_return(
        status: 200,
        body: { StatusResults: {} }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    refute_predicate status_check, :successful?
    assert_nil status_check.status
  end

  def test_handles_missing_status_results_key
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .to_return(
        status: 200,
        body: {}.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    # Should not raise an error, just return nil values
    refute_predicate status_check, :successful?
    assert_nil status_check.status
    assert_nil status_check.reservation_details
  end

  def test_works_with_different_restaurant_ids
    opts = @valid_opts.merge(restaurant_id: 99_999)
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .with(query: hash_including('rid' => '99999'))
      .to_return(
        status: 200,
        body: successful_status_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    status_check = Hungrytable::ReservationStatus.new(opts)

    assert_predicate status_check, :successful?
  end

  def test_works_with_different_confirmation_numbers
    opts = @valid_opts.merge(confirmation_number: 'CONF999999')
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .with(query: hash_including('conf' => 'CONF999999'))
      .to_return(
        status: 200,
        body: successful_status_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    status_check = Hungrytable::ReservationStatus.new(opts)
    details = status_check.reservation_details

    # Confirmation number in details should match what was passed in
    assert_equal 'CONF999999', details[:confirmation_number]
  end

  def test_handles_partial_response_data
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .to_return(
        status: 200,
        body: {
          StatusResults: {
            'ns:ErrorID' => '0',
            'ns:ReservationStatus' => 'Confirmed'
            # Missing other fields
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    status_check = Hungrytable::ReservationStatus.new(@valid_opts)

    assert_predicate status_check, :successful?
    assert_equal 'Confirmed', status_check.status

    details = status_check.reservation_details

    assert_equal 'Confirmed', details[:status]
    assert_nil details[:restaurant_name]
    assert_nil details[:date_time]
    assert_nil details[:party_size]
  end

  private

  def stub_successful_status_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .to_return(
        status: 200,
        body: successful_status_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_failed_status_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .to_return(
        status: 200,
        body: failed_status_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_cancelled_status_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .to_return(
        status: 200,
        body: cancelled_status_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_seated_status_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .to_return(
        status: 200,
        body: seated_status_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_status_response_with_large_party
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservationstatus/})
      .to_return(
        status: 200,
        body: large_party_status_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def successful_status_json
    {
      StatusResults: {
        'ns:ErrorID' => '0',
        'ns:ReservationStatus' => 'Confirmed',
        'ns:RestaurantName' => 'Test Restaurant',
        'ns:DateTime' => '2025-02-01 19:00:00',
        'ns:PartySize' => '4'
      }
    }.to_json
  end

  def failed_status_json
    {
      StatusResults: {
        'ns:ErrorID' => '1',
        'ns:ErrorMessage' => 'Reservation not found'
      }
    }.to_json
  end

  def cancelled_status_json
    {
      StatusResults: {
        'ns:ErrorID' => '0',
        'ns:ReservationStatus' => 'Cancelled',
        'ns:RestaurantName' => 'Test Restaurant',
        'ns:DateTime' => '2025-02-01 19:00:00',
        'ns:PartySize' => '4'
      }
    }.to_json
  end

  def seated_status_json
    {
      StatusResults: {
        'ns:ErrorID' => '0',
        'ns:ReservationStatus' => 'Seated',
        'ns:RestaurantName' => 'Test Restaurant',
        'ns:DateTime' => '2025-02-01 19:00:00',
        'ns:PartySize' => '4'
      }
    }.to_json
  end

  def large_party_status_json
    {
      StatusResults: {
        'ns:ErrorID' => '0',
        'ns:ReservationStatus' => 'Confirmed',
        'ns:RestaurantName' => 'Large Party Restaurant',
        'ns:DateTime' => '2025-02-15 18:00:00',
        'ns:PartySize' => '12'
      }
    }.to_json
  end
end
