module Hungrytable
  class ReservationCancel
    attr_reader :opts

    def initialize opts={}
      @opts = opts
      ensure_required_opts
      handle_initial_request
    end

    def successful?
      details["ns:ErrorID"] == "0"
    end

    private
    def handle_initial_request
      @initial_request = GetRequest.new("/reservation/?pid=#{Config.partner_id}&rid=#{opts[:restaurant_id]}&conf=#{opts[:confirmation_number]}&email=#{CGI.escape(opts[:email_address])}")
    end

    def details
      @initial_request.parsed_response["Results"]
    end

    def ensure_required_opts
      [:email_address, :confirmation_number, :restaurant_id].each do |key|
        raise ArgumentError, "options must include a value for #{key}" unless opts.has_key?(key)
      end
    end
  end
end
