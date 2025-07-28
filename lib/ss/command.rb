# rubocop:disable Metrics/ParameterLists
class SS::Command
  NULL_DEVICE = "/dev/null".freeze

  class << self
    def run_async(*commands, mod: nil, stdin: false, stdout: false, stderr: false, chdir: nil)
      pid = do_spawn(*commands, mod: mod, stdin: stdin, stdout: stdout, stderr: stderr, chdir: chdir)
      Process.detach(pid)
    end

    def run(*commands, mod: nil, stdin: false, stdout: false, stderr: false, chdir: nil)
      pid = do_spawn(*commands, mod: mod, stdin: stdin, stdout: stdout, stderr: stderr, chdir: chdir)
      _, status = Process.waitpid2(pid)
      status
    end

    private

    def do_spawn(*commands, mod:, stdin:, stdout:, stderr:, chdir:)
      options = {}
      options[:in] = stdin ? stdin : NULL_DEVICE
      options[:out] = stdout ? stdout : NULL_DEVICE
      options[:err] = stderr ? stderr : NULL_DEVICE
      options[:chdir] = chdir if chdir

      mod ||= Kernel
      mod.spawn({}, *commands, options)
    end
  end
end
# rubocop:enable Metrics/ParameterLists
