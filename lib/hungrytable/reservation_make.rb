module Hungrytable
  class ReservationMake
    include RequestExtensions

    attr_reader :restaurant_slotlock, :opts

    def initialize restaurant_slotlock, opts={}
      @opts = opts
      ensure_required_opts
      @requester           = opts[:requester] || PostRequest
      @restaurant_slotlock = restaurant_slotlock
    end

    def successful?
      details["ns:ErrorID"] == "0"
    end

    def confirmation_number
      return nil unless successful?
      details["ns:ConfirmationNumber"]
    end

    private
    def required_opts
      %w(email_address firstname lastname phone).map(&:to_sym)
    end

    def default_options
      {
        'OTannouncementOption' => '0',
        'RestaurantEmailOption' => '0',
        'firsttimediner' => '0',
        'specialinstructions' => 'Have a great time',
        'slotlockid' => restaurant_slotlock.slotlock_id
      }.merge(restaurant_slotlock.params)
    end

    def params
      default_options.merge(opts)
    end

    def request_uri
      "/reservation/?pid=#{Config.partner_id}&st=0"
    end

    def details
      request.parsed_response["MakeResults"]
    end

  end
end
