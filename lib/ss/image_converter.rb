class SS::ImageConverter
  class << self
    def resize_to_fit(ss_file, width, height)
      input = ss_file.path
      output = "#{ss_file.path}.$$"

      env = {}
      options = { in: SS::RakeRunner::NULL_DEVICE, out: SS::RakeRunner::NULL_DEVICE, err: SS::RakeRunner::NULL_DEVICE }

      if SS.config.ss.image_magick.present? && SS.config.ss.image_magick["convert"].present?
        commands = [ SS.config.ss.image_magick["convert"] ]
      else
        commands = [ "/usr/bin/env", "convert" ]
      end
      commands << "-resize"
      commands << "#{width}x#{height}"
      commands << input
      commands << output

      pid = spawn(env, *commands, options)
      _, status = Process.waitpid2(pid)
      if status.success?
        ::FileUtils.move(output, input)
      end

      status.success?
    ensure
      ::FileUtils.rm_f(output)
    end
  end
end
