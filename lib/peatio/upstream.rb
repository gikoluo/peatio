# frozen_string_literal: true

require 'peatio/upstream/base'
require 'peatio/upstream/opendax'

module Peatio
  module Upstream
    class << self
      def registry
        @registry ||= Registry.new
      end

      class Registry < Peatio::AdapterRegistry
      end
    end
  end
end
