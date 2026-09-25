module SS
  module DownloadHelpers
    TIMEOUT = ENV.fetch("DOWNLOAD_MAX_WAIT_TIME", 1).to_i

    module_function

    def path
      @path ||= begin
        path = Rails.root.join('tmp/spec/downloads')
        ::FileUtils.mkdir_p(path)
        path.to_s
      end
    end

    def downloads
      ::Dir["#{path}/*"]
    end

    def downloaded_path
      @downloaded_path
    end

    def wait_for_download(pattern, extname: nil)
      matchers = []

      if pattern.is_a?(Regexp)
        matchers << proc { |file| ::File.basename(file) =~ pattern }
      elsif pattern.is_a?(String)
        matchers << proc { |file| ::File.basename(file).include?(pattern) }
      else
        raise "wait_for_download : invalid pattern"
      end

      if extname.present?
        matchers << proc { |file| ::File.extname(file) == extname }
      end

      clear_downloads
      @downloaded_path = nil

      yield

      ::Timeout.timeout(TIMEOUT) do
        loop do
          @downloaded_path = downloads.find do |file|
            matchers.all? { |proc| proc.call(file) }
          end
          return @downloaded_path if @downloaded_path
          sleep 0.1
        end
      end
    rescue ::Timeout::Error
      raise ::Timeout::Error, "wait_for_download : timeout(#{TIMEOUT}) with #{[pattern, extname].join(", ")}"
    end

    def clear_downloads
      ::FileUtils.rm_f(downloads)
    end

    def enable_headless_chrome_download(driver)
      return unless driver.is_a?(Capybara::Selenium::Driver)
      return unless driver.options[:browser] == :chrome

      @enabled_chromes ||= {}

      bridge = driver.browser.send(:bridge)
      return if @enabled_chromes[bridge.session_id]

      path = "/session/#{bridge.session_id}/chromium/send_command"
      cmd = {
        cmd: 'Page.setDownloadBehavior',
        params: {
          behavior: 'allow',
          downloadPath: SS::DownloadHelpers.path
        }
      }
      bridge.http.call(:post, path, cmd)
      @enabled_chromes[bridge.session_id] = true
    end

    module Helper
      def self.extended(obj)
        obj.before(:each) do
          SS::DownloadHelpers.enable_headless_chrome_download(page.driver)
          SS::DownloadHelpers.clear_downloads
        end

        obj.class_eval do
          delegate :downloads, to: SS::DownloadHelpers
          delegate :downloaded_path, to: SS::DownloadHelpers
          delegate :wait_for_download, to: SS::DownloadHelpers
          delegate :clear_downloads, to: SS::DownloadHelpers
        end
      end
    end

  end
end

RSpec.configuration.extend(SS::DownloadHelpers::Helper, js: true)
