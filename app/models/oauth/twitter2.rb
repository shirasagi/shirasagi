require 'oauth'

class OAuth::Twitter2 < OmniAuth::Strategies::Twitter2
  include OAuth::Base
end
