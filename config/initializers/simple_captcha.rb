SimpleCaptcha.setup do |sc|
  # default: 5
  sc.length = 4
end

module SimpleCaptcha
  class SimpleCaptchaData
    if client = Mongoid::Config.clients[:default_post]
      store_in client: :default_post, database: client[:database]
    end
  end
end
