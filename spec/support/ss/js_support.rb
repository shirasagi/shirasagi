module SS
  module JsSupport
    def wait_for_ajax(selector, timeout = 10)
      start_at = Time.zone.now.to_i
      while !page.has_selector?(selector) && (Time.zone.now.to_i - start_at) < timeout
        sleep 0.1
      end
    end

    def wait_for_cbox(timeout = 10)
      wait_for_ajax("div#ajax-box table.index", timeout)
    end
  end
end
