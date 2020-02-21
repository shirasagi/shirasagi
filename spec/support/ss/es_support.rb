module SS
  module EsSupport
    module Hooks
      def self.extended(obj)
        obj.after do
          WebMock.reset!
        end
      end
    end
  end
end

RSpec.configuration.extend(SS::EsSupport::Hooks, es: true)
