module Hungrytable
  module RequestExtensions
    extend ActiveSupport::Concern

    private
    def request
      @request ||= @requester.new(request_uri, params)
    end

    def ensure_required_opts
      required_opts.each do |key|
        raise ArgumentError, "options must include a value for #{key}" unless opts.has_key?(key)
      end
    end

    # Will be overwritten in objects that send post requests
    def params
      {}
    end
  end
end
