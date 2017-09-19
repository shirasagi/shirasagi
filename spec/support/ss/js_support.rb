module SS
  module JsSupport
    def ajax_timeout
      @ajax_timeout ||= 30
    end

    def ajax_timeout=(timeout)
      @ajax_timeout = timeout
    end

    def finished_all_ajax_requests?
      page.evaluate_script('jQuery.active').zero?
    end

    def wait_for_ajax(&block)
      unless block_given?
        return wait_for_ajax &method(:finished_all_ajax_requests?)
      end

      start_at = Time.zone.now.to_f
      sleep 0.1 while !yield && (Time.zone.now.to_f - start_at) < ajax_timeout
    end

    def wait_for_selector(*args)
      wait_for_ajax do
        page.has_selector?(*args)
      end
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

    def wait_for_cbox
      wait_for_selector("div#ajax-box table.index")
    end

    def wait_for_cbox_close
      Timeout.timeout(ajax_timeout) do
        loop do
          yield if block_given?
          break if colorbox_closed?
          sleep 1
        end
      end
    end

    def save_full_screenshot(opts = {})
      filename = opts[:filename].presence || "#{Rails.root}/tmp/screenshots-#{Time.zone.now.to_i}"
      page.save_screenshot(filename, full: true)
      puts "screenshot: #{filename}"
    rescue
    end
  end
end

RSpec.configuration.include(SS::JsSupport, js: true)
