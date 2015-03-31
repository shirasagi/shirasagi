module SS
  module ColorBoxSupport
    def wait_for_cbox(timeout = 10)
      start_at = Time.now.to_i
      while !page.has_selector?("div#ajax-box table.index") && (Time.now.to_i - start_at) < timeout do
        sleep 0.1
      end
    end
  end
end
