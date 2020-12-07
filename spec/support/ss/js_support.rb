module SS
  module JsSupport
    module Hooks
      def self.extended(obj)
        obj.after(:example) do
          warnings = jquery_migrate_warnings
          if warnings.present?
            puts
            "[JQMIGRATE] #{self.inspect}".try do |msg|
              Rails.logger.warn msg
              puts msg
            end
            warnings.each do |warning|
              "[JQMIGRATE][WARNING] #{warning}".try do |msg|
                Rails.logger.warn msg
                puts msg
              end
            end
          end
          wait_for_page_load
          wait_for_ajax
        end
      end
    end

    HOOK_CBOX_COMPLETION = "
      (function(promiseId) {
        var defer = $.Deferred();
        $(document).one('cbox_complete', function() { defer.resolve(true); });
        window.SS[promiseId] = defer.promise();
      })(arguments[0]);
    ".freeze

    WAIT_CBOX_COMPLETION = "
      (function(promiseId, resolve) {
        var promise = window.SS[promiseId];
        if (!promise) {
          resolve(false);
          return;
        }

        delete window.SS[promiseId];
        promise.done(function() { resolve(true); });
      })(arguments[0], arguments[1]);
    ".freeze

    CLOSE_COLORBOX_AND_WAIT_SCRIPT = "
      (function(resolve) {
        var $element = $.colorbox.element();
        if (!$element) {
          // a colorbox isn't opened
          resolve(false);
          return;
        }

        $element.colorbox({ onClosed: function() { resolve(true); } });
        $.colorbox.close();
      })(arguments[0]);
    ".freeze

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

    #
    # Usage:
    #   open_cbox_and_wait do
    #     click_on I18n.t("ss.buttons.upload")
    #   end
    #
    def open_cbox_and_wait
      promise_id = "promise_#{unique_id}"
      page.execute_script(HOOK_CBOX_COMPLETION, promise_id)

      yield

      ret = page.evaluate_async_script(WAIT_CBOX_COMPLETION, promise_id)
      expect(ret).to be_truthy
    end

    def close_cbox_and_wait
      ret = page.evaluate_async_script(CLOSE_COLORBOX_AND_WAIT_SCRIPT)
      expect(ret).to be_truthy
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

    def capture_console_logs
      page.driver.browser.manage.logs.get(:browser).collect(&:message)
    rescue => _e
    end

    def puts_console_logs
      logs = capture_console_logs
      return if logs.blank?

      puts
      puts "==== console.log (#{caller(1, 1).try(:first)}) ===="
      puts logs
      puts
    end

    def enable_js_debug
      page.execute_script("SS.debug = true;")
    rescue => _e
    end

    def disable_js_debug
      page.execute_script("SS.debug = false;")
    rescue => _e
    end
  end
end

RSpec.configuration.extend(SS::JsSupport::Hooks, js: true)
RSpec.configuration.include(SS::JsSupport, js: true)
