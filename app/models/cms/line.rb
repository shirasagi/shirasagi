module Cms::Line
  #https://github.com/line/line-bot-sdk-ruby/blob/master/lib/line/bot/client.rb
  mattr_accessor :max_members_to
  self.max_members_to = 400
end
