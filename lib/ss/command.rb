class SS::Command
  NULL_DEVICE = "/dev/null".freeze

  class << self
    def run_async(*commands, stdin: false, stdout: false, stderr: false)
      pid = do_spawn(*commands, stdin: stdin, stdout: stdout, stderr: stderr)
      Process.detach(pid)
    end

    def run(*commands, stdin: false, stdout: false, stderr: false)
      pid = do_spawn(*commands, stdin: stdin, stdout: stdout, stderr: stderr)
      _, status = Process.waitpid2(pid)
      status
    end

    private

    def do_spawn(*commands, stdin:, stdout:, stderr:)
      options = {}
      options[:in] = stdin ? stdin : NULL_DEVICE
      options[:out] = stdout ? stdout : NULL_DEVICE
      options[:err] = stderr ? stderr : NULL_DEVICE
      spawn({}, *commands, options)
    end
  end
end
