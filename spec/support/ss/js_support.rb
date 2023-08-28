module SS
  module JsSupport
    module Hooks
      def self.extended(obj)
        # callback は登録の逆順に呼ばれるので、先に non_unique_id! を登録する
        Capybara::Session.set_callback :visit, :after do |session|
          SS::JsSupport.non_unique_id!(session)
        end
        Capybara::Session.set_callback :visit, :after do |session|
          SS::JsSupport.wait_for_js_ready(session)
        rescue => _e
          # csv や pdf などに遷移した場合、WAIT_FOR_JS_READY_SCRIPT は失敗し例外を発生させるが、無視する
        end

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

    mattr_accessor :is_within_cbox

    module_function

    HOOK_EVENT_COMPLETION = <<~SCRIPT.freeze
      (function(promiseId, eventName, selector) {
        var defer = $.Deferred();
        $(selector || document).one(eventName, function() { defer.resolve(true); });
        window.SS[promiseId] = defer.promise();
      })(...arguments)
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
      })(...arguments)
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
      })(...arguments)
    SCRIPT

    WAIT_CKEDITOR_READY_SCRIPT = <<~SCRIPT.freeze
      (function(element, resolve) {
        var ckeditor = $(element).ckeditor().editor;
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
      })(...arguments)
    SCRIPT

    WAIT_ALL_CKEDITORS_READY_SCRIPT = <<~SCRIPT.freeze
      (function(resolve) {
        var promises = [];
        Object.values(CKEDITOR.instances).forEach(function(ckeditor) {
          if (ckeditor.status === "ready") {
            console.log("ckeditor is ready");
            promises.push(Promise.resolve(true));
            return;
          }

          var promise = new Promise((resolutionFunc, rejectionFunc) => {
            ckeditor.once("instanceReady", function() {
              console.log("ckeditor gets ready");
              resolutionFunc(true);
            });
          });
          promises.push(promise);
        });

        Promise.all(promises).then(function() { setTimeout(function() { resolve(true); }, 0); });
      })(...arguments)
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
      })(...arguments)
    SCRIPT

    HOOK_CKEDITOR_EVENT_COMPLETION = <<~SCRIPT.freeze
      (function(promiseId, element, eventName) {
        var ckeditor = $(element).ckeditor().editor;
        var defer = $.Deferred();
        ckeditor.once(eventName, function(ev) { defer.resolve(true); ev.removeListener(); });
        window.SS[promiseId] = defer.promise();
      })(...arguments)
    SCRIPT

    IMAGE_ELEMENT_INFO = <<~SCRIPT.freeze
      (function(element, resolve) {
        if (! element.decode) {
          resolve({ error: "not a HTMLImageElement" });
          return;
        }
        element.decode().then(() => {
          resolve({
            width: element.width,
            height: element.height,
            naturalWidth: element.naturalWidth,
            naturalHeight: element.naturalHeight,
            currentSrc: element.currentSrc,
          });
        }).catch((error) => {
          resolve({ error: error.toString() });
          return true;
        });
      })(...arguments)
    SCRIPT

    WAIT_FOR_JS_READY_SCRIPT = <<~SCRIPT.freeze
      (function(resolve) {
        if ("SS" in window) {
          SS.ready(function() { resolve(true); });
          return;
        }

        if (document.readyState === "complete") {
          // document が読み込まれているのに SS が存在しない場合、現在のところリカバリ方法が不明
          resolve(false);
          return;
        }

        window.addEventListener("load", function() {
          if ("SS" in window) {
            SS.ready(function() { resolve(true); });
          } else {
            resolve(false);
          }
        });
      })(...arguments)
    SCRIPT

    FILL_DATETIME_SCRIPT = <<~SCRIPT.freeze
      (function(element, value, resolve) {
        var setter = function() {
          var pickerInstance = SS_DateTimePicker.instance(element);
          pickerInstance.momentValue(value ? moment(value) : null);

          // validate を実行するとイベント "ss:changeDateTime" が発生する。
          // イベント "ss:changeDateTime" のハンドラーのいくつかで別　URL へ遷移するものがある。
          // そのようなもので stale element reference エラーが発生することを防ぐため、
          // setTimeout 内で validate を実行するようにする。
          // ※ setTimeout 内で validate を実行すると、stale element reference エラーがなぜ発生しなくなるかは不明。
          setTimeout(function() {
            $(element).datetimepicker("validate");
            resolve(true);
          }, 0);
        }

        var pickerInstance = SS_DateTimePicker.instance(element);
        if (pickerInstance && pickerInstance.initialized) {
          setter();
        } else {
          $(element).one("ss:generate", setter);
        }
      })(...arguments)
    SCRIPT

    JS_SELECT_SCRIPT = <<~SCRIPT.freeze
      (function(element, valueText) {
        const optionIndex = Array.from(element.options).findIndex(option => option.text === valueText);
        element.selectedIndex = optionIndex;
      })(...arguments)
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

    def fill_in_code_mirror(locator, **options)
      with = options.delete(:with)
      options[:visible] = :all

      wait_for_js_ready

      element = find(:fillable_field, locator, **options)
      page.execute_script("$(arguments[0]).data('editor').setValue(arguments[1])", element, with)
    end

    def native_fill_in(locator = nil, with:)
      el = find(:fillable_field, locator).set('').click
      with.to_s.chars.each { |c| el.native.send_keys(c) }
      el
    rescue Selenium::WebDriver::Error::WebDriverError
      el
    end

    def finished_all_ajax_requests?
      active = page.evaluate_script('jQuery.active') rescue nil
      active.nil? || active.zero?
    end

    def wait_for_selector(*args)
      Timeout.timeout(wait_timeout) do
        sleep 1 until page.has_selector?(*args)
      end
      yield if block_given?
    end

    def wait_for_cbox(&block)
      wait_for_js_ready
      have_css("#cboxClose", text: "close")
      if block
        save = JsSupport.is_within_cbox
        JsSupport.is_within_cbox = true
        begin
          within("#cboxContent", &block)
        ensure
          JsSupport.is_within_cbox = save
        end
      end
    end

    def colorbox_opened?
      opacity = page.evaluate_script("$('#cboxOverlay').css('opacity')")
      opacity.nil? ? true : (opacity.to_f >= 0.9)
    end

    def colorbox_closed?
      opacity = page.evaluate_script("$('#cboxOverlay').css('opacity')")
      opacity.nil? ? true : opacity.to_f.zero?
    end

    def datetimepicker_value(locator, **options)
      date = options.delete(:date)
      options[:visible] = :all

      element = find(:fillable_field, locator, **options)
      value = page.evaluate_script("$(arguments[0]).data('xdsoft_datetimepicker').getValue().toJSON()", element)
      format = date ? I18n.t("date.formats.picker") : I18n.t("time.formats.picker")
      Time.zone.parse(value).strftime(format)
    end

    def wait_for_page_load
      page.document.synchronize do
        current_path
        true
      end
      wait_for_js_ready
    end

    def wait_for_notice(text)
      wait_for_js_ready
      expect(page).to have_css('#notice', text: text)
      page.execute_script("SS.clearNotice();")
      wait_for_js_ready
    end

    def wait_for_error(text)
      wait_for_js_ready
      expect(page).to have_css('#errorExplanation', text: text)
      page.execute_script("SS.clearNotice();")
      wait_for_js_ready
    end

    def save_full_screenshot(**opts)
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

    def capture_console_logs(session = nil)
      case Capybara.javascript_driver
      when :firefox
        # currently not supported on firefox
        []
      else
        session ||= page
        session.driver.browser.logs.get(:browser).collect(&:message)
      end
    rescue => _e
      []
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

    def non_unique_id!(session = nil)
      session ||= page
      console_messages = capture_console_logs(session)
      if console_messages && console_messages.any? { |message| message.include?("non-unique id") }
        raise "there are non-unique elements"
      end
    end

    def wait_event_to_fire(event_name, selector = nil)
      wait_for_js_ready

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
      wait_for_js_ready
      wait_event_to_fire("cbox_complete", &block)
      wait_for_js_ready
    end

    #
    # Usage:
    #   wait_cbox_close do
    #     # do operations to close a colorbox
    #     click_on user.name
    #   end
    #
    def wait_cbox_close(&block)
      wait_for_js_ready
      save = JsSupport.is_within_cbox
      JsSupport.is_within_cbox = true
      wait_event_to_fire("cbox_closed", &block)
    ensure
      JsSupport.is_within_cbox = save
    end

    #
    # Usage:
    #   ensure_addon_opened("#addon-contact-agents-addons-page")
    #
    def ensure_addon_opened(addon_id)
      wait_for_js_ready
      result = page.evaluate_async_script(ENSURE_ADDON_OPENED, addon_id)
      expect(result).to be_truthy
      true
    end

    #
    # Usage
    #   wait_ckeditor_ready find(:fillable_field, "item[html]")
    #
    def wait_ckeditor_ready(element)
      wait_for_js_ready
      page.evaluate_async_script(WAIT_CKEDITOR_READY_SCRIPT, element)
    end

    #
    # Usage
    #   wait_all_ckeditors_ready
    #
    def wait_all_ckeditors_ready
      wait_for_js_ready
      page.evaluate_async_script(WAIT_ALL_CKEDITORS_READY_SCRIPT)
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
    def fill_in_ckeditor(locator, **options)
      with = options.delete(:with)
      options[:visible] = :all
      element = find(:fillable_field, locator, **options)

      ret = wait_ckeditor_ready(element)
      expect(ret).to be_truthy
      ret = page.evaluate_async_script(FILL_CKEDITOR_SCRIPT, element, with)
      expect(ret).to be_truthy
    end

    def fill_in_datetime(locator, **options)
      wait_for_js_ready

      element = find(:fillable_field, locator, visible: :all)
      with = options.delete(:with)
      with = with.in_time_zone.iso8601 if with.present?

      page.evaluate_script(FILL_DATETIME_SCRIPT, element, with)
      #result = page.evaluate_async_script(FILL_DATETIME_SCRIPT, element, with)
      #expect(result).to be_truthy
    end

    alias fill_in_date fill_in_datetime

    #
    # Usage:
    #   wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
    #     # do operations to cause "afterInsertHtml" event on "item[html]"
    #     click_on I18n.t("sns.thumb_paste")
    #   end
    #
    def wait_for_ckeditor_event(locator, event_name)
      element = find(:fillable_field, locator)

      ret = wait_ckeditor_ready(element)
      expect(ret).to be_truthy

      promise_id = "promise_#{unique_id}"
      page.execute_script(HOOK_CKEDITOR_EVENT_COMPLETION, promise_id, element, event_name)

      # do operations which fire events
      ret = yield

      result = page.evaluate_async_script(WAIT_EVENT_COMPLETION, promise_id)
      expect(result).to be_truthy

      ret
    end

    def image_element_info(element)
      result = page.evaluate_async_script(IMAGE_ELEMENT_INFO, element)
      expect(result).to be_present
      expect(result).to be_a(Hash)

      result.symbolize_keys!
      expect(result[:error]).to be_blank

      result
    end

    # document.readyState が 'loading' になるのを待機する。
    #
    # switch_to_window や within_window で別ウインドウに切り替えた直後、document.readyState が 'uninitialized' となっている場合がある。
    # この場合、window.addEventListener, window.setTimeout, document.addEventListener などを呼び出すとエラー "Document was unloaded"
    # が発生する。
    #
    # JS コードで待機できれば良いのだが、setTimeout が使用できないので Ruby コードで待機する。
    def wait_for_document_loading
      Timeout.timeout(wait_timeout) do
        loop do
          ready_state = page.evaluate_script("document.readyState")
          break if ready_state.present? && ready_state != 'uninitialized'

          sleep 0.1
        end
      end
    end

    def wait_for_js_ready(session = nil, &block)
      session ||= page
      unless session.evaluate_async_script(WAIT_FOR_JS_READY_SCRIPT)
        puts_console_logs
        raise "unable to be js ready"
      end

      yield if block
    rescue Selenium::WebDriver::Error::JavascriptError
      puts_console_logs
      raise
    end
    alias wait_for_ajax wait_for_js_ready

    def click_on(locator = nil, **options)
      if JsSupport.is_within_cbox
        click_on_cbox(locator, **options)
      else
        page.click_on(locator, **options)
      end
    end

    def click_on_cbox(locator, **options)
      case Capybara.javascript_driver
      when :firefox
        # firefox で colorbox 上の <a> をクリックすると、ElementNotInteractableError が発生する
        # JS でクリックしてこのエラーを回避する
        # see: https://github.com/teamcapybara/capybara/blob/3.38.0/lib/capybara/node/actions.rb#L25-L28
        js_click find(:link_or_button, locator, **options)
      else
        page.click_on(locator, **options)
      end
    end

    def js_click(element)
      wait_for_js_ready
      page.execute_script("arguments[0].click()", element)
    end

    def js_dispatch_generic_event(element, event_name)
      wait_for_js_ready
      page.execute_script("arguments[0].dispatchEvent(new Event(arguments[1]))", element, event_name)
      wait_for_js_ready
    end

    def js_dispatch_focus_event(element, event_name)
      wait_for_js_ready
      page.execute_script("arguments[0].dispatchEvent(new FocusEvent(arguments[1]))", element, event_name)
      wait_for_js_ready
    end

    def fill_in_address(locator, with:)
      wait_for_js_ready
      wait_event_to_fire("ss:addressCommitted") do
        fill_in locator, with: with
        js_dispatch_focus_event find(:fillable_field, locator), 'blur'
      end
    end

    def js_select(value, from:, **options)
      wait_for_js_ready
      element = find(:select, from, **options)
      page.execute_script(JS_SELECT_SCRIPT, element, value)
      js_dispatch_generic_event(element, "change")
    end
  end
end

# monkey patch to capybara/session
module Capybara
  class Session
    include ActiveSupport::Callbacks

    define_callbacks :visit

    def visit_with_shirasagi(*args, **options)
      run_callbacks :visit do
        visit_without_shirasagi(*args, **options)
      end
    end

    alias visit_without_shirasagi visit
    alias visit visit_with_shirasagi
  end
end

RSpec.configuration.extend(SS::JsSupport::Hooks, js: true)
RSpec.configuration.include(SS::JsSupport, js: true)
