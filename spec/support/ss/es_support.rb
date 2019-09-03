module SS
  module EsSupport
    module Callbacks
      def self.extended(obj)
        obj.after do
          WebMock.reset!
        end
      end
    end
  end
end

RSpec.configuration.extend(SS::EsSupport::Callbacks, es: true)
RSpec.configuration.include(SS::EsSupport, es: true)
