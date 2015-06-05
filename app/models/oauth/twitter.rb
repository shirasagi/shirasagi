require 'oauth'

class Oauth::Twitter < OmniAuth::Strategies::Twitter
  include Oauth::Base

  # override OmniAuth::Strategies::OAuth#consumer
  def consumer
    consumer = ::OAuth::Consumer.new(client_id, client_secret, options.client_options)
    consumer.http.open_timeout = options.open_timeout if options.open_timeout
    consumer.http.read_timeout = options.read_timeout if options.read_timeout
    consumer
  end
end
