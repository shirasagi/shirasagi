SimpleCaptcha.setup do |sc|
  # default: 5
  sc.length = 4
end

module SimpleCaptcha
  class SimpleCaptchaData
    if Mongoid::Config.clients[:default_post]
      store_in client: :default_post
    end
  end
end
