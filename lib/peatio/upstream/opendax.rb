# frozen_string_literal: true

module Peatio
  module Upstream
    class Opendax < Base
      def initialize(config)
        super
        @connection = Faraday.new(url: "#{config['rest']}") do |builder|
          builder.response :json
          builder.response :logger if config["debug"]
          builder.adapter(@adapter)
          builder.ssl[:verify] = config["verify_ssl"] unless config["verify_ssl"].nil?
        end
        @rest = "#{config['rest']}"
        @ws_url = "#{config['websocket']}/public"
      end
    end
  end
end
