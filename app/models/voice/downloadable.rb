require 'open-uri'
require 'resolv-replace'
require 'timeout'

module Voice::Downloadable
  DEFAULT_ATTEMPTS = 3
  INITIAL_WAIT = 1
  TIMEOUT_SEC = 3

  def download(max_attempts = DEFAULT_ATTEMPTS, timeout_sec = TIMEOUT_SEC)
    with_retry(max_attempts) do
      timeout(timeout_sec) do
        # class must provide a method 'url'
        open(url) do |f|
          status_code = f.status[0]
          html = f.read if status_code == '200'

          [ html.force_encoding("utf-8"), f.last_modified ]
        end
      end
    end
  end

  private
    def with_retry(max_attempts = DEFAULT_ATTEMPTS, initial_wait = INITIAL_WAIT)
      num_attempts = 0
      wait = initial_wait

      begin
        yield
      rescue TimeoutError, StandardError
        num_attempts += 1
        raise if num_attempts >= max_attempts

        sleep wait
        wait *= 2
        retry
      end
    end
end
