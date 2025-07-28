module SS
  module DownloadHelpers
    TIMEOUT = ENV.fetch("DOWNLOAD_MAX_WAIT_TIME", 1).to_i

    module_function

    def path
      @path ||= begin
        path = Rails.root.join('tmp/spec/downloads')
        ::FileUtils.mkdir_p(path) if !::Dir.exist?(path)
        path.to_s
      end
    end

    def downloads
      ::Dir["#{path}/*"]
    end

    def wait_for_download
      ::Timeout.timeout(TIMEOUT) do
        sleep 0.1 while downloading?
      end
    end

    def downloaded?
      !downloading?
    end

    def downloading?
      downloads.grep(/\.crdownload$/).any? || downloads.blank?
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
          delegate :wait_for_download, to: SS::DownloadHelpers
          delegate :clear_downloads, to: SS::DownloadHelpers
        end
      end
    end

  end
end

RSpec.configuration.extend(SS::DownloadHelpers::Helper, js: true)
