module SS
  module JsSupport
    module Hooks
      def self.extended(obj)
        obj.after(:example) do
          warnings = jquery_migrate_warnings
          if warnings.present?
            warnings.each do |warning|
              Rails.logger.warn "[JQMIGRATE][WARNING] #{warning}"
              puts "[JQMIGRATE][WARNING] #{warning}"
            end
          end
          wait_for_page_load
          wait_for_ajax
        end
      end
    end

    def wait_timeout
      Capybara.default_max_wait_time
    end

    def ajax_timeout
      @ajax_timeout ||= (ENV["CAPYBARA_AJAX_WAIT_TIME"] || 20).to_i
    end

    def ajax_timeout=(timeout)
      @ajax_timeout = timeout
    end

    def visit(*args)
      super
      wait_for_page_load
      wait_for_ajax
    end

    # fill_in(locator = nil, with:, currently_with: nil, fill_options: {}, **find_options)
    def fill_in(locator = nil, with:, currently_with: nil, fill_options: {}, **find_options)
      el = super
      (el.value.to_s.strip == with.to_s.strip) ? el : native_fill_in(locator, with: with)
    end

    def native_fill_in(locator = nil, with:)
      el = find(:fillable_field, locator).set('').click
      with.to_s.split('').each { |c| el.native.send_keys(c) }
      el
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      el
    rescue Selenium::WebDriver::Error::ElementClickInterceptedError
      el
    end

    def finished_all_ajax_requests?
      active = page.evaluate_script('jQuery.active') rescue nil
      active.nil? || active.zero?
    end

    def wait_for_ajax(&block)
      Timeout.timeout(ajax_timeout) do
        sleep 1 until finished_all_ajax_requests?
      end
      if block_given?
        sleep 1
        yield
      end
    end

    def wait_for_selector(*args)
      Timeout.timeout(wait_timeout) do
        sleep 1 until page.has_selector?(*args)
      end
      yield if block_given?
    end

    def wait_for_cbox(&block)
      wait_for_ajax
      has_css?("#cboxLoadedContent")
      has_css?("#cboxClose")
      Timeout.timeout(ajax_timeout) do
        sleep 1 until colorbox_opened?
      end
      if block_given?
        within "#cboxContent" do
          yield
        end
        wait_for_ajax
        sleep 1
      end
    end

    def wait_for_cbox_close(&block)
      wait_for_ajax
      Timeout.timeout(ajax_timeout) do
        sleep 1 until colorbox_closed?
      end
      yield if block_given?
    end

    def colorbox_opened?
      opacity = page.evaluate_script("$('#cboxOverlay').css('opacity')")
      opacity.nil? ? true : (opacity.to_f == 0.9)
    end

    def colorbox_closed?
      opacity = page.evaluate_script("$('#cboxOverlay').css('opacity')")
      opacity.nil? ? true : (opacity.to_f == 0)
    end

    def wait_for_page_load
      page.document.synchronize do
        current_path
        true
      end
    end

    def wait_for_notice(text)
      wait_for_page_load
      wait_for_ajax
      expect(page).to have_css('#notice', text: text)
    end

    def wait_for_error(text)
      wait_for_page_load
      wait_for_ajax
      expect(page).to have_css('#errorExplanation', text: text)
    end

    def save_full_screenshot(opts = {})
      filename = opts[:filename].presence || "#{Rails.root}/tmp/screenshots-#{Time.zone.now.to_f}.png"
      page.save_screenshot(filename, full: true)
      puts "screenshot: #{filename}"
    rescue
    end

    def jquery_migrate_warnings
      page.evaluate_script("jQuery.migrateWarnings") rescue nil
    end

    def jquery_migrate_reset
      page.execute_script("jQuery.migrateReset();")
    end
  end
end

RSpec.configuration.extend(SS::JsSupport::Hooks, js: true)
RSpec.configuration.include(SS::JsSupport, js: true)
