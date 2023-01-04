class SS::MaxFileSize
  include SS::Model::MaxFileSize
  include Sys::Permission

  set_permission_name "sys_users", :edit

  class << self
    def nginx_client_max_body_size(mod: nil)
      return @nginx_client_max_body_size if @nginx_client_max_body_size

      Tempfile.create('conf') do |file|
        status_code = fetch_nginx_config(file, mod: mod)
        if status_code == 0
          @nginx_client_max_body_size = load_nginx_client_max_body_size(file)
        else
          Rails.logger.info("unable to load nginx's client_max_body_size")
        end

        if SS.config.env.nginx_client_max_body_size
          @nginx_client_max_body_size ||= SS::Size.parse(SS.config.env.nginx_client_max_body_size)
        end
        @nginx_client_max_body_size ||= SS::Model::MaxFileSize::MAX_FILE_SIZE
      end
    end

    def clear_nginx_client_max_body_size
      @nginx_client_max_body_size = nil
    end

    private

    def fetch_nginx_config(file, mod: nil)
      mod ||= Kernel
      pid = mod.spawn({}, "nginx", "-T", { in: SS::RakeRunner::NULL_DEVICE, out: file.fileno, err: SS::RakeRunner::NULL_DEVICE })
      status_code, _status = Process.waitpid2(pid)
      status_code
    rescue => e
      Rails.logger.info("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      $CHILD_STATUS ? $CHILD_STATUS.exitstatus : -1
    end

    def load_nginx_client_max_body_size(file)
      file.rewind
      file.each_line do |line|
        comment_index = line.index("#")
        if comment_index
          line = line[0..comment_index]
        end
        next unless line =~ /client_max_body_size\s+(\d+\w?)/

        size = $1
        return SS::Size.parse(size)
      end

      nil
    end
  end
end
