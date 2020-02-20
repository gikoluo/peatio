# frozen_string_literal: true

module Peatio
  module Upstream
    class Base
      DEFAULT_DELAY = 1
      WEBSOCKET_CONNECTION_RETRY_DELAY = 2

      def initialize(opts)
        @host = opts["url"]
        @adapter = opts[:faraday_adapter] || :em_synchrony
        @opts = opts
        @ws_queues = EM::Queue.new
        @ws_status = false
        @market = opts['source']
      end

      def ws_connect
        Rails.logger.info { "Websocket connecting to #{@ws_url}" }
        raise "websocket url missing for account #{id}" unless @ws_url

        @ws = Faye::WebSocket::Client.new(@ws_url)

        @ws.on(:open) do |_e|
          on_open_trades(@market, @ws)
          Rails.logger.info { "Websocket connected" }
        end

        @ws.on(:message) do |msg|
          ws_read_message(msg)
        end

        @ws.on(:close) do |e|
          @ws = nil
          @ws_status = false
          Rails.logger.error "Websocket disconnected: #{e.code} Reason: #{e.reason}"
          Fiber.new do
            EM::Synchrony.sleep(WEBSOCKET_CONNECTION_RETRY_DELAY)
            ws_connect
          end.resume
        end
      end

      def on_open_trades(market, ws)
        sub = {
          event:   "subscribe",
          streams: ["#{market}.trades"],
        }

        Rails.logger.info "Open event" + sub.to_s
        EM.next_tick {
          ws.send(JSON.generate(sub))
        }
      end

      def ws_connect_public
        ws_connect
      end

      def ws_read_public_message(msg)
        Rails.logger.info { "received public message: #{msg}" }
      end

      def ws_read_message(msg)
        Rails.logger.debug {"received websocket message: #{msg.data}" }

        object = JSON.parse(msg.data)
        ws_read_public_message(object)
        # if object.keys.first.split('.') == 'trades'
        #   ::AMQP::Queue.enqueue_event("public", market.id, "trades", {trades: [for_global]})
        # end
      end

      def to_s
        "Exchange::#{self.class} config: #{@opts}"
      end

      def build_error(response)
        JSON.parse(response.body)
      rescue StandardError => e
        "Code: #{response.env.status} Message: #{response.env.reason_phrase}"
      end
    end
  end
end
