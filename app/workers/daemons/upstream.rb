# frozen_string_literal: true

module Workers
  module Daemons
    class Upstream < Base
      def run
        Market.all.map {|m| m if m.metadata.present? }.compact.map { |m| Thread.new { process(m) } }.map(&:join)
      end

      def process(market)
        EM.synchrony do
          upstream = market.metadata['upstream']
          Peatio::Upstream.registry[upstream['driver']].new(upstream.merge('source' => market.id)).ws_connect
          Rails.logger.info "Upstream #{market.metadata['upstream']} started"
        end
      end

      def stop
        puts 'Shutting down'
        @shutdown = true
        exit(42)
      end
    end
  end
end
