module Hungrytable
  class ReservationCancel
    include RequestExtensions

    attr_reader :opts

    def initialize opts={}
      @opts = opts
      ensure_required_opts
      @requester = opts[:requester] || GetRequest
    end

    def successful?
      details["ns:ErrorID"] == "0"
    end

    private
    def request_uri
      "/reservation/?pid=#{Config.partner_id}&rid=#{opts[:restaurant_id]}&conf=#{opts[:confirmation_number]}&email=#{CGI.escape(opts[:email_address])}"
    end

    def details
      request.parsed_response["Results"]
    end

    def required_opts
      %w(email_address confirmation_number restaurant_id).map(&:to_sym)
    end
  end
end
