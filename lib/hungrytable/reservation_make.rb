module Hungrytable
  class ReservationMake
    attr_reader :restaurant_slotlock, :opts

    def initialize restaurant_slotlock, opts={}
      @opts = opts
      ensure_required_opts
      @restaurant_slotlock = restaurant_slotlock
      handle_initial_request
    end

    def successful?
      details["ns:ErrorID"] == "0"
    end

    def confirmation_number
      return nil unless successful?
      details["ns:ConfirmationNumber"]
    end

    private
    def ensure_required_opts
      [:email_address, :firstname, :lastname, :phone].each do |key|
        raise ArgumentError, "options must include a value for #{key}" unless opts.has_key?(key)
      end
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

    def handle_initial_request
      @initial_request = PostRequest.new("/reservation/?pid=#{Config.partner_id}&st=0", params)
    end

    def details
      @initial_request.parsed_response["MakeResults"]
    end

  end
end
