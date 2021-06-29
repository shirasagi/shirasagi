module SS
  module JsSupport
    module Hooks
      def self.extended(obj)
        show_warning = ENV.fetch("JQMIGRATE_WARNING", nil)
        return unless show_warning

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
        end
      end
    end

    HOOK_EVENT_COMPLETION = <<~SCRIPT.freeze
      (function(promiseId, eventName, selector) {
        var defer = $.Deferred();
        $(selector || document).one(eventName, function() { defer.resolve(true); });
        window.SS[promiseId] = defer.promise();
      })(arguments[0], arguments[1], arguments[2]);
    SCRIPT

    WAIT_EVENT_COMPLETION = <<~SCRIPT.freeze
      (function(promiseId, resolve) {
        var promise = window.SS[promiseId];
        if (!promise) {
          resolve(false);
          return;
        }

        delete window.SS[promiseId];
        promise.done(function(result) { resolve(result); });
      })(arguments[0], arguments[1]);
    SCRIPT

    ENSURE_ADDON_OPENED = <<~SCRIPT.freeze
      (function(addonId, resolve) {
        var $addon = $(addonId);
        if (! $addon[0]) {
          resolve(false);
          return;
        }

        if ($addon.hasClass("hide")) {
          resolve(false);
          return;
        }

        if (! $addon.hasClass("body-closed")) {
          resolve(true);
          return;
        }

        $addon.one("ss:addonShown", function() { resolve(true); });
        $addon.find(".toggle-head").trigger("click");
      })(arguments[0], arguments[1]);
    SCRIPT

    WAIT_CKEDITOR_READY_SCRIPT = <<~SCRIPT.freeze
      (function(selector, resolve) {
        var ckeditor = $(selector).ckeditor().editor;
        if (!ckeditor) {
          console.log("ckeditor is not available");
          resolve(false);
          return;
        }
        if (ckeditor.status === "ready") {
          console.log("ckeditor is ready");
          resolve(true);
          return;
        }

        ckeditor.once("instanceReady", function() {
          console.log("ckeditor gets ready");
          setTimeout(function() { resolve(true); }, 0);
        });
      })(arguments[0], arguments[1]);
    SCRIPT

    FILL_CKEDITOR_SCRIPT = <<~SCRIPT.freeze
      (function(element, text, resolve) {
        var ckeditor = CKEDITOR.instances[element.id];
        if (!ckeditor) {
          resolve(false);
          return;
        }

        var callback = function() {
          setTimeout(function() {
            resolve(true);
          }, 0);
        };

        ckeditor.setData(text, { callback: callback });
      })(arguments[0], arguments[1], arguments[2]);
    SCRIPT

    HOOK_CKEDITOR_EVENT_COMPLETION = <<~SCRIPT.freeze
      (function(promiseId, selector, eventName) {
        var ckeditor = $(selector).ckeditor().editor;
        var defer = $.Deferred();
        ckeditor.once(eventName, function(ev) { defer.resolve(true); ev.removeListener(); });
        window.SS[promiseId] = defer.promise();
      })(arguments[0], arguments[1], arguments[2]);
    SCRIPT

    def wait_timeout
      Capybara.default_max_wait_time
    end

    def ajax_timeout
      @ajax_timeout ||= (ENV["CAPYBARA_AJAX_WAIT_TIME"] || 20).to_i
    end

    def ajax_timeout=(timeout)
      @ajax_timeout = timeout
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
      have_css("#cboxClose", text: "close")
      within("#cboxContent", &block) if block_given?
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
      expect(page).to have_css('#notice', text: text)
    end

    def wait_for_error(text)
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

    def wait_event_to_fire(event_name, selector = nil)
      promise_id = "promise_#{unique_id}"
      page.execute_script(HOOK_EVENT_COMPLETION, promise_id, event_name, selector)

      # do operations which fire events
      ret = yield

      result = page.evaluate_async_script(WAIT_EVENT_COMPLETION, promise_id)
      expect(result).to be_truthy

      ret
    end

    #
    # Usage:
    #   wait_cbox_open do
    #     # do operations to open a colorbox
    #     click_on I18n.t("ss.buttons.upload")
    #   end
    #
    def wait_cbox_open(&block)
      wait_event_to_fire("cbox_complete", &block)
    end

    #
    # Usage:
    #   wait_cbox_close do
    #     # do operations to close a colorbox
    #     click_on user.name
    #   end
    #
    def wait_cbox_close(&block)
      wait_event_to_fire("cbox_closed", &block)
    end

    #
    # Usage:
    #   ensure_addon_opened("#addon-contact-agents-addons-page")
    #
    def ensure_addon_opened(addon_id)
      result = page.evaluate_async_script(ENSURE_ADDON_OPENED, addon_id)
      expect(result).to be_truthy
      true
    end

    #
    # Usage
    #   wait_for_ckeditor_event "item[html]"
    #
    def wait_ckeditor_ready(locator)
      page.evaluate_async_script(WAIT_CKEDITOR_READY_SCRIPT, "[name=\"#{locator}\"]")
    end

    # CKEditor に html を設定する
    #
    # CKEditor の setData メソッドを用いて HTML を設定する。
    # CKEditor の setData メソッドは非同期のため、HTML 設定直後にアクセシビリティのチェックや携帯データサイズチェックを実行すると、
    # setData 完了前（つまり空）の HTML でチェックを実行していまし、正しくチェックができない場合がある。
    #
    # そこで、本メソッドでは setData の完了まで待機する。
    #
    # 参照: https://ckeditor.com/docs/ckeditor4/latest/api/CKEDITOR_editor.html#method-setData
    def fill_in_ckeditor(locator, options = {})
      with = options.delete(:with)
      options[:visible] = :all
      element = find(:fillable_field, locator, options)

      ret = wait_ckeditor_ready(locator)
      expect(ret).to be_truthy
      ret = page.evaluate_async_script(FILL_CKEDITOR_SCRIPT, element, with)
      expect(ret).to be_truthy
    end

    #
    # Usage:
    #   wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
    #     # do operations to cause "afterInsertHtml" event on "item[html]"
    #     click_on I18n.t("sns.thumb_paste")
    #   end
    #
    def wait_for_ckeditor_event(locator, event_name)
      ret = wait_ckeditor_ready(locator)
      expect(ret).to be_truthy

      promise_id = "promise_#{unique_id}"
      page.execute_script(HOOK_CKEDITOR_EVENT_COMPLETION, promise_id, "[name=\"#{locator}\"]", event_name)

      # do operations which fire events
      ret = yield

      result = page.evaluate_async_script(WAIT_EVENT_COMPLETION, promise_id)
      expect(result).to be_truthy

      ret
    end
  end
end

RSpec.configuration.extend(SS::JsSupport::Hooks, js: true)
RSpec.configuration.include(SS::JsSupport, js: true)
