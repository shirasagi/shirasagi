module Pippi
  class GdChat
    class << self
      def logger
        @logger ||= begin
          Logger.new((Rails.root + "log/gd_chat.log").to_s, 'daily')
        end
        @logger
      end
    end
  end
end
