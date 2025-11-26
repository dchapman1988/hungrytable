# frozen_string_literal: true

module Hungrytable
  # Makes a new restaurant reservation
  class ReservationMake
    include RequestExtensions

    attr_reader :restaurant_slotlock, :opts

    def initialize(restaurant_slotlock, opts = {})
      @opts = opts
      ensure_required_opts
      @requester = opts[:requester] || PostRequest
      @restaurant_slotlock = restaurant_slotlock
    end

    # Check if the reservation was successful
    # @return [Boolean] true if no errors
    def successful?
      details['ns:ErrorID'] == '0'
    end

    # Get the confirmation number for the reservation
    # @return [String, nil] confirmation number or nil if unsuccessful
    def confirmation_number
      return nil unless successful?

      details['ns:ConfirmationNumber']
    end

    # Get error messages if reservation failed
    # @return [String, nil] error message or nil
    def error_message
      details['ns:ErrorMessage']
    end

    private

    def required_opts
      %i[email_address firstname lastname phone]
    end

    def default_options
      {
        'OTannouncementOption' => '0',
        'RestaurantEmailOption' => '0',
        'firsttimediner' => '0',
        'specialinstructions' => opts[:specialinstructions] || '',
        'slotlockid' => restaurant_slotlock.slotlock_id
      }.merge(restaurant_slotlock.params)
    end

    def params
      # Convert symbol keys to strings for API
      user_opts = opts.transform_keys(&:to_s)
      default_options.merge(user_opts)
    end

    def request_uri
      "/reservation/?pid=#{Config.partner_id}&st=0"
    end

    # @return [Hash] reservation results from API response
    def details
      @details ||= request.parsed_response['MakeResults'] || {}
    end
  end
end
