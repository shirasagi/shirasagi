module SS::CapybaraSupport
  module Hooks
    def self.extended(obj)
      default_raise_server_errors_setting = Capybara.raise_server_errors
      raise_server_errors_setting = obj.metadata[:raise_server_errors]

      if !raise_server_errors_setting.nil?
        obj.before(:example) do
          Capybara.raise_server_errors = raise_server_errors_setting
          puts "[Capybara] raise_server_errors : #{Capybara.raise_server_errors}"
        end
        obj.after(:example) do
          Capybara.raise_server_errors = default_raise_server_errors_setting
        end
      end
    end
  end

  module_function

  def activate_driver(name, config)
    case name
    when 'firefox'
      activate_firefox(config)
    when 'random'
      [ true, false ].sample ? activate_chrome(config) : activate_firefox(config)
    else # 'chrome'
      activate_chrome(config)
    end
  rescue LoadError
    deactivate_driver(config)
  end

  def activate_chrome(config)
    require 'selenium-webdriver'
    headless = ENV.fetch('headless', '1')
    set_capybara_server
    Capybara.register_driver :chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_preference('download.prompt_for_download', false)
      options.add_preference('download.default_directory', SS::DownloadHelpers.path)
      options.add_argument('window-size=1280,800')
      options.add_argument('log-level=0')
      options.add_argument('lang=ja-JP')
      if headless != '0'
        options.add_argument('headless=new')
        options.add_argument('disable-gpu')
        if ENV.fetch('sandbox', '0') != '0' || ci?
          options.add_argument('no-sandbox')
        end
      end
      options.add_option("goog:loggingPrefs", { browser: "ALL" })

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.javascript_driver = :chrome

    puts "[Capybara] with Google Chrome(headless: #{headless == '0' ? 'disabled' : 'enabled'})"
    true
  end

  MIME_TYPES_FOR_DOWNLOAD = %w(
    text/plain text/csv text/xml image/png image/jpeg image/gif application/pdf application/zip application/octet-stream
  ).freeze

  def activate_firefox(config)
    require 'selenium-webdriver'
    headless = ENV.fetch('headless', '1')
    set_capybara_server
    Capybara.register_driver :firefox do |app|
      profile = Selenium::WebDriver::Firefox::Profile.new
      # ダウンロード
      profile['browser.download.dir'] = SS::DownloadHelpers.path
      profile['browser.download.folderList'] = 2
      profile['browser.download.manager.alertOnEXEOpen'] = false
      profile['browser.download.manager.closeWhenDone'] = true
      profile['browser.download.manager.focusWhenStarting'] = false
      profile['browser.download.manager.showAlertOnComplete'] = false
      profile['browser.download.manager.showWhenStarting'] = false
      profile['browser.download.manager.useWindow'] = false
      profile['browser.helperApps.alwaysAsk.force'] = false
      profile['browser.helperApps.neverAsk.saveToDisk'] = MIME_TYPES_FOR_DOWNLOAD.join(",")
      # 国際化
      profile['intl.accept_languages'] = 'ja-JP'

      options = Selenium::WebDriver::Options.firefox(profile: profile)
      options.log_level = 'trace'
      options.add_argument('--width=1280')
      options.add_argument('--height=800')

      if headless != '0'
        options.add_argument('--headless')
      end

      Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
    end
    Capybara.javascript_driver = :firefox

    puts "[Capybara] with Firefox(headless: #{headless == '0' ? 'disabled' : 'enabled'})"
    true
  end

  def set_capybara_server
    if ENV.fetch('capybara_server', 'puma') == "puma"
      Capybara.server = :puma, { Silent: false }
    else
      Capybara.server = :webrick
    end
  end

  def deactivate_driver(config)
    config.filter_run_excluding(js: true)
    false
  end
end

RSpec.configuration.extend(SS::CapybaraSupport::Hooks)
