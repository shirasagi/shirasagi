module SS
  module JsSupport
    module Callbacks
      def self.extended(obj)
        obj.after do
          page.reset! # unless finished_all_ajax_requests?
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
      wait_for_ajax
    end

    def fill_in(selector, options)
      with = options[:with]

      if options[:native] # original option
        el = super(selector, with: '')
        return native_fill_in(el, with)
      end
      el = super(selector, with: with)
      return native_fill_in(el, with) if el.value.to_s.strip != with.to_s.strip
      el
    end

    def native_fill_in(el, with)
      el.set('').click
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
        sleep 1 while !finished_all_ajax_requests?
      end
      yield if block_given?
    end

    def wait_for_selector(*args)
      Timeout.timeout(wait_timeout) do
        sleep 1 while !page.has_selector?(*args)
      end
      yield if block_given?
    end

    def wait_for_cbox(&block)
      wait_for_ajax
      wait_for_selector("#cboxLoadedContent")
      wait_for_selector("#cboxClose")
      within "#cboxContent" do
        yield if block_given?
      end
    end

    def wait_for_cbox_close(&block)
      find("#cboxClose").click if has_css?("#cboxClose")
      wait_for_ajax

      Timeout.timeout(ajax_timeout) do
        sleep 1 while !colorbox_closed?
      end
      yield if block_given?
    end

    def colorbox_opened?
      opacity = page.evaluate_script("$('#cboxOverlay').css('opacity')")
      return true if opacity.nil?
      opacity.to_f == 0.9
    end

    def colorbox_closed?
      opacity = page.evaluate_script("$('#cboxOverlay').css('opacity')")
      return true if opacity.nil?
      opacity.to_f == 0
    end

    def save_full_screenshot(opts = {})
      filename = opts[:filename].presence || "#{Rails.root}/tmp/screenshots-#{Time.zone.now.to_i}"
      page.save_screenshot(filename, full: true)
      puts "screenshot: #{filename}"
    rescue
    end
  end
end

RSpec.configuration.extend(SS::JsSupport::Callbacks, js: true)
RSpec.configuration.include(SS::JsSupport, js: true)
