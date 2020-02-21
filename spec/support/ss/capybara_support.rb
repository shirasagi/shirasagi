module SS::CapybaraSupport
  module_function

  def activate_driver(name, config)
    activate_chrome(config)
  rescue LoadError
    deactivate_driver(config)
  end

  def activate_chrome(config)
    require 'selenium-webdriver'
    headless = ENV.fetch('headless', '1')
    Capybara.server = :webrick
    Capybara.register_driver :chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_preference('download.prompt_for_download', false)
      options.add_preference('download.default_directory', SS::DownloadHelpers.path)
      options.add_argument('window-size=1280,800')
      if headless != '0'
        options.add_argument('headless')
        options.add_argument('disable-gpu')
        if ENV.fetch('sandbox', '0') != '0' || (ENV["CI"] == "true" && ENV["TRAVIS"] == "true")
          options.add_argument('no-sandbox')
        end
      end

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.javascript_driver = :chrome

    puts "[Capybara] with Google Chrome(headless: #{headless != '0' ? 'enabled' : 'disabled'})"
    true
  end

  def deactivate_driver(config)
    config.filter_run_excluding(js: true)
    false
  end
end
