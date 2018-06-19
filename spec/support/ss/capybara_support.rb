module SS::CapybaraSupport
  module_function

  def chrome_installed?
    return true if system("which chromedriver > /dev/null 2>&1")
    return true if ::File.exist?('/usr/lib/chromium-browser/chromedriver')
    home = ENV['HOME']
    return true if ::File.exist?("#{home}/chromedriver")
    false
  end

  def phantomjs_installed?
    system("which phantomjs > /dev/null 2>&1")
  end

  def auto_detect_driver
    return :chrome if chrome_installed?
    return :poltergeist if phantomjs_installed?
  end

  def activate_driver(name, config)
    case name.try(:to_sym)
    when :auto
      activate_driver(auto_detect_driver, config)
    when :chrome
      activate_chrome(config)
    when :poltergeist, :phantomjs
      activate_poltergeist(config)
    else
      deactivate_driver(config)
    end
  rescue LoadError
    deactivate_driver(config)
  end

  def activate_chrome(config)
    require 'selenium-webdriver'
    Capybara.server = :webrick
    Capybara.register_driver :chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_preference('download.prompt_for_download', false)
      options.add_preference('download.default_directory', SS::DownloadHelpers.path)
      options.add_argument('window-size=1680,1050')
      if ENV.fetch('headless', '1') != '0'
        options.add_argument('headless')
        options.add_argument('disable-gpu')
        if ENV.fetch('sandbox', '0') != '0' || (ENV["CI"] == "true" && ENV["TRAVIS"] == "true")
          options.add_argument('no-sandbox')
        end
      end

      if ::File.exist?('/usr/lib/chromium-browser/chromedriver')
        Selenium::WebDriver::Chrome.driver_path ||= '/usr/lib/chromium-browser/chromedriver'
      end
      home = ENV['HOME']
      if ::File.exist?("#{home}/chromedriver")
        Selenium::WebDriver::Chrome.driver_path ||= "#{home}/chromedriver"
      end

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.javascript_driver = :chrome
    Capybara.default_max_wait_time = 15

    config.before( :each ) do
      SS::DownloadHelpers::clear_downloads
    end

    config.filter_run_excluding(driver: :poltergeist)
    puts '[Capybara] with Google Chrome'
    true
  end

  def activate_poltergeist(config)
    require 'capybara/poltergeist'
    Capybara.server = :webrick
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, inspector: true)
    end
    Capybara.javascript_driver = :poltergeist
    Capybara.default_max_wait_time = 15

    config.filter_run_excluding(driver: :chrome)
    puts '[Capybara] with Poltergeist/PhantomJS'
    true
  end

  def deactivate_driver(config)
    config.filter_run_excluding(js: true)
    false
  end
end
