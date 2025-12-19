# frozen_string_literal: true

require 'test_helper'

class ReservationMakeTest < Minitest::Test
  def setup
    setup_config
    @restaurant = Hungrytable::Restaurant.new(12_345)

    # Create a mock restaurant search
    @restaurant_search = Minitest::Mock.new
    @restaurant_search.expect :restaurant, @restaurant
    @restaurant_search.expect :ideal_time, '2025-02-01 19:00:00'
    @restaurant_search.expect :party_size, 4
    @restaurant_search.expect :ideal_security_id, 'exact_sec_456'
    @restaurant_search.expect :results_key, 'results_key_abc123'

    # Create a mock slotlock
    @slotlock = Minitest::Mock.new
    @slotlock.expect :slotlock_id, 'slotlock_xyz789'
    @slotlock.expect :params, {
      'RID' => 12_345,
      'datetime' => '2025-02-01 19:00:00',
      'partysize' => 4,
      'timesecurityID' => 'exact_sec_456',
      'resultskey' => 'results_key_abc123'
    }

    @valid_opts = {
      email_address: 'test@example.com',
      firstname: 'John',
      lastname: 'Doe',
      phone: '555-1234'
    }
  end

  def teardown
    teardown_config
    WebMock.reset!
  end

  # Initialization tests
  def test_initialization_with_slotlock_and_options
    # Use a simple stub instead of mock to avoid strict method checking in initialization
    stub_slotlock = Object.new
    reservation = Hungrytable::ReservationMake.new(stub_slotlock, @valid_opts)

    assert_equal stub_slotlock, reservation.restaurant_slotlock
    assert_equal @valid_opts, reservation.opts
  end

  def test_initialization_raises_error_when_email_address_missing
    opts = @valid_opts.dup
    opts.delete(:email_address)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationMake.new(@slotlock, opts)
    end

    assert_includes error.message, 'email_address'
  end

  def test_initialization_raises_error_when_firstname_missing
    opts = @valid_opts.dup
    opts.delete(:firstname)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationMake.new(@slotlock, opts)
    end

    assert_includes error.message, 'firstname'
  end

  def test_initialization_raises_error_when_lastname_missing
    opts = @valid_opts.dup
    opts.delete(:lastname)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationMake.new(@slotlock, opts)
    end

    assert_includes error.message, 'lastname'
  end

  def test_initialization_raises_error_when_phone_missing
    opts = @valid_opts.dup
    opts.delete(:phone)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationMake.new(@slotlock, opts)
    end

    assert_includes error.message, 'phone'
  end

  def test_initialization_raises_error_when_all_required_fields_missing
    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationMake.new(@slotlock, {})
    end

    assert_includes error.message, 'email_address'
    assert_includes error.message, 'firstname'
    assert_includes error.message, 'lastname'
    assert_includes error.message, 'phone'
  end

  # successful? method tests
  def test_successful_returns_true_when_error_id_is_zero
    stub_successful_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    assert_predicate reservation, :successful?
  end

  def test_successful_returns_false_when_error_id_is_not_zero
    stub_failed_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    refute_predicate reservation, :successful?
  end

  # confirmation_number method tests
  def test_confirmation_number_returns_number_when_successful
    stub_successful_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    assert_equal 'CONF123456', reservation.confirmation_number
  end

  def test_confirmation_number_returns_nil_when_unsuccessful
    stub_failed_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    assert_nil reservation.confirmation_number
  end

  # error_message method tests
  def test_error_message_returns_nil_when_successful
    stub_successful_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    assert_nil reservation.error_message
  end

  def test_error_message_returns_message_when_unsuccessful
    stub_failed_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    assert_equal 'Reservation could not be completed', reservation.error_message
  end

  def test_error_message_returns_different_messages
    stub_invalid_email_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    assert_equal 'Invalid email address', reservation.error_message
  end

  # params method tests
  def test_params_merges_default_options_with_user_options
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)
    params = reservation.send(:params)

    # Check default options are present
    assert_equal '0', params['OTannouncementOption']
    assert_equal '0', params['RestaurantEmailOption']
    assert_equal '0', params['firsttimediner']
    assert_equal '', params['specialinstructions']

    # Check slotlock data is present
    assert_equal 'slotlock_xyz789', params['slotlockid']
    assert_equal 12_345, params['RID']
    assert_equal '2025-02-01 19:00:00', params['datetime']
    assert_equal 4, params['partysize']

    # Check user options are present (as strings)
    assert_equal 'test@example.com', params['email_address']
    assert_equal 'John', params['firstname']
    assert_equal 'Doe', params['lastname']
    assert_equal '555-1234', params['phone']
  end

  def test_params_includes_special_instructions_when_provided
    opts = @valid_opts.merge(specialinstructions: 'Window seat please')
    reservation = Hungrytable::ReservationMake.new(@slotlock, opts)
    params = reservation.send(:params)

    assert_equal 'Window seat please', params['specialinstructions']
  end

  def test_params_uses_empty_string_for_special_instructions_when_not_provided
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)
    params = reservation.send(:params)

    assert_equal '', params['specialinstructions']
  end

  def test_params_converts_symbol_keys_to_strings
    # Verify that symbol keys from user options are converted to strings
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)
    params = reservation.send(:params)

    # All keys should be strings
    params.each_key do |key|
      assert_instance_of String, key
    end
  end

  def test_params_filters_out_internal_options
    # Verify that internal options like :requester are not sent to the API
    opts_with_requester = @valid_opts.merge(requester: Minitest::Mock.new)
    reservation = Hungrytable::ReservationMake.new(@slotlock, opts_with_requester)
    params = reservation.send(:params)

    # :requester should not be in the params sent to API
    refute_includes params.keys, 'requester'
    refute_includes params.keys, :requester

    # Valid options should still be present
    assert_equal 'test@example.com', params['email_address']
    assert_equal 'John', params['firstname']
  end

  # Request URI tests
  def test_request_uri_includes_partner_id
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)
    uri = reservation.send(:request_uri)

    assert_includes uri, 'pid=test_partner_id'
  end

  def test_request_uri_includes_st_parameter
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)
    uri = reservation.send(:request_uri)

    assert_includes uri, 'st=0'
  end

  def test_request_uri_format
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)
    uri = reservation.send(:request_uri)

    assert_equal '/reservation/?pid=test_partner_id&st=0', uri
  end

  # Integration tests with WebMock
  def test_handles_successful_api_response_correctly
    stub_successful_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    assert_predicate reservation, :successful?
    assert_equal 'CONF123456', reservation.confirmation_number
    assert_nil reservation.error_message
  end

  def test_handles_failed_api_response_correctly
    stub_failed_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    refute_predicate reservation, :successful?
    assert_nil reservation.confirmation_number
    assert_equal 'Reservation could not be completed', reservation.error_message
  end

  def test_handles_invalid_email_response
    stub_invalid_email_reservation_response
    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    refute_predicate reservation, :successful?
    assert_nil reservation.confirmation_number
    assert_equal 'Invalid email address', reservation.error_message
  end

  # Edge case tests
  def test_handles_empty_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: { MakeResults: {} }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    refute_predicate reservation, :successful?
    assert_nil reservation.confirmation_number
  end

  def test_handles_missing_make_results_key
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: {}.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    reservation = Hungrytable::ReservationMake.new(@slotlock, @valid_opts)

    # Should not raise an error, just return nil values
    refute_predicate reservation, :successful?
    assert_nil reservation.confirmation_number
  end

  def test_accepts_additional_optional_fields
    opts = @valid_opts.merge(
      specialinstructions: 'Allergy to peanuts',
      RestaurantEmailOption: '1',
      OTannouncementOption: '1'
    )

    reservation = Hungrytable::ReservationMake.new(@slotlock, opts)
    params = reservation.send(:params)

    assert_equal 'Allergy to peanuts', params['specialinstructions']
    # User-provided values should override defaults
    assert_equal '1', params['RestaurantEmailOption']
    assert_equal '1', params['OTannouncementOption']
  end

  private

  def stub_successful_reservation_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: successful_reservation_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_failed_reservation_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: failed_reservation_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_invalid_email_reservation_response
    stub_request(:post, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: invalid_email_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def successful_reservation_json
    {
      MakeResults: {
        'ns:ErrorID' => '0',
        'ns:ConfirmationNumber' => 'CONF123456'
      }
    }.to_json
  end

  def failed_reservation_json
    {
      MakeResults: {
        'ns:ErrorID' => '1',
        'ns:ErrorMessage' => 'Reservation could not be completed'
      }
    }.to_json
  end

  def invalid_email_json
    {
      MakeResults: {
        'ns:ErrorID' => '2',
        'ns:ErrorMessage' => 'Invalid email address'
      }
    }.to_json
  end
end
