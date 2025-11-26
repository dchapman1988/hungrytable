# frozen_string_literal: true

require 'test_helper'

class ReservationCancelTest < Minitest::Test
  def setup
    setup_config
    @valid_opts = {
      email_address: 'test@example.com',
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
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    assert_equal @valid_opts, cancellation.opts
  end

  def test_initialization_raises_error_when_email_address_missing
    opts = @valid_opts.dup
    opts.delete(:email_address)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationCancel.new(opts)
    end

    assert_includes error.message, 'email_address'
  end

  def test_initialization_raises_error_when_confirmation_number_missing
    opts = @valid_opts.dup
    opts.delete(:confirmation_number)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationCancel.new(opts)
    end

    assert_includes error.message, 'confirmation_number'
  end

  def test_initialization_raises_error_when_restaurant_id_missing
    opts = @valid_opts.dup
    opts.delete(:restaurant_id)

    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationCancel.new(opts)
    end

    assert_includes error.message, 'restaurant_id'
  end

  def test_initialization_raises_error_when_all_required_fields_missing
    error = assert_raises(Hungrytable::MissingRequiredFieldError) do
      Hungrytable::ReservationCancel.new({})
    end

    assert_includes error.message, 'email_address'
    assert_includes error.message, 'confirmation_number'
    assert_includes error.message, 'restaurant_id'
  end

  # successful? method tests
  def test_successful_returns_true_when_error_id_is_zero
    stub_successful_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    assert_predicate cancellation, :successful?
  end

  def test_successful_returns_false_when_error_id_is_not_zero
    stub_failed_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    refute_predicate cancellation, :successful?
  end

  # error_message method tests
  def test_error_message_returns_nil_when_successful
    stub_successful_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    assert_nil cancellation.error_message
  end

  def test_error_message_returns_message_when_unsuccessful
    stub_failed_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    assert_equal 'Reservation not found', cancellation.error_message
  end

  def test_error_message_returns_different_error_messages
    stub_invalid_email_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    assert_equal 'Email does not match reservation', cancellation.error_message
  end

  def test_error_message_when_cancellation_window_passed
    stub_too_late_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    assert_equal 'Cannot cancel within 2 hours of reservation', cancellation.error_message
  end

  # Request URI tests
  def test_request_uri_includes_partner_id
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)
    uri = cancellation.send(:request_uri)

    assert_includes uri, 'pid=test_partner_id'
  end

  def test_request_uri_includes_restaurant_id
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)
    uri = cancellation.send(:request_uri)

    assert_includes uri, 'rid=12345'
  end

  def test_request_uri_includes_confirmation_number
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)
    uri = cancellation.send(:request_uri)

    assert_includes uri, 'conf=CONF123456'
  end

  def test_request_uri_includes_encoded_email_address
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)
    uri = cancellation.send(:request_uri)

    # Email should be CGI escaped
    assert_includes uri, 'email='
    assert_includes uri, 'test%40example.com'
  end

  def test_request_uri_properly_encodes_email_with_plus_sign
    opts = @valid_opts.merge(email_address: 'test+tag@example.com')
    cancellation = Hungrytable::ReservationCancel.new(opts)
    uri = cancellation.send(:request_uri)

    # Plus sign should be encoded
    assert_includes uri, 'test%2Btag%40example.com'
  end

  def test_request_uri_format
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)
    uri = cancellation.send(:request_uri)

    expected_uri = '/reservation/?pid=test_partner_id&rid=12345&conf=CONF123456&email=test%40example.com'

    assert_equal expected_uri, uri
  end

  # Integration tests with WebMock
  def test_handles_successful_api_response_correctly
    stub_successful_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    assert_predicate cancellation, :successful?
    assert_nil cancellation.error_message
  end

  def test_handles_failed_api_response_correctly
    stub_failed_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    refute_predicate cancellation, :successful?
    assert_equal 'Reservation not found', cancellation.error_message
  end

  def test_handles_invalid_email_response
    stub_invalid_email_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    refute_predicate cancellation, :successful?
    assert_equal 'Email does not match reservation', cancellation.error_message
  end

  def test_handles_too_late_to_cancel_response
    stub_too_late_cancel_response
    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    refute_predicate cancellation, :successful?
    assert_equal 'Cannot cancel within 2 hours of reservation', cancellation.error_message
  end

  # Edge case tests
  def test_handles_empty_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: { Results: {} }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    refute_predicate cancellation, :successful?
  end

  def test_handles_missing_results_key
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: {}.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cancellation = Hungrytable::ReservationCancel.new(@valid_opts)

    # Should not raise an error, just return nil values
    refute_predicate cancellation, :successful?
    assert_nil cancellation.error_message
  end

  def test_works_with_different_restaurant_ids
    opts = @valid_opts.merge(restaurant_id: 99_999)
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .with(query: hash_including('rid' => '99999'))
      .to_return(
        status: 200,
        body: successful_cancel_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cancellation = Hungrytable::ReservationCancel.new(opts)

    assert_predicate cancellation, :successful?
  end

  def test_works_with_different_confirmation_numbers
    opts = @valid_opts.merge(confirmation_number: 'CONF999999')
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .with(query: hash_including('conf' => 'CONF999999'))
      .to_return(
        status: 200,
        body: successful_cancel_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cancellation = Hungrytable::ReservationCancel.new(opts)

    assert_predicate cancellation, :successful?
  end

  private

  def stub_successful_cancel_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: successful_cancel_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_failed_cancel_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: failed_cancel_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_invalid_email_cancel_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: invalid_email_cancel_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_too_late_cancel_response
    stub_request(:get, %r{#{Regexp.escape(Hungrytable::Config.base_url)}/reservation/})
      .to_return(
        status: 200,
        body: too_late_cancel_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def successful_cancel_json
    {
      Results: {
        'ns:ErrorID' => '0'
      }
    }.to_json
  end

  def failed_cancel_json
    {
      Results: {
        'ns:ErrorID' => '1',
        'ns:ErrorMessage' => 'Reservation not found'
      }
    }.to_json
  end

  def invalid_email_cancel_json
    {
      Results: {
        'ns:ErrorID' => '2',
        'ns:ErrorMessage' => 'Email does not match reservation'
      }
    }.to_json
  end

  def too_late_cancel_json
    {
      Results: {
        'ns:ErrorID' => '3',
        'ns:ErrorMessage' => 'Cannot cancel within 2 hours of reservation'
      }
    }.to_json
  end
end
