require 'guard/compat/plugin'
require 'rainbow'

module Guard
  class Stylelint < Plugin
    attr_reader :options, :config

    def self.non_namespaced_name
      'stylelint'
    end

    def initialize(options = {})
      super

      @options = { all_on_start: true }.merge(options)

      # load_config

      # @scss_lint_runner = SCSSLint::Runner.new @config
      # @failed_paths     = []
    end

    def start
      Guard::Compat::UI.info "Guard::Stylelint is running"
      run_all if @options[:all_on_start]
    end

    def reload
      puts "#reload"
    end

    def run_all
      puts "#run_all"
      Guard::Compat::UI.info 'Running Stylelint for all .scss files'
      pattern = File.join '**', '*.scss'
      paths   = Guard::Compat.matching_files(self, Dir.glob(pattern))
      run_on_changes paths
    end

    def run_on_changes(paths)
      # paths = paths.reject { |p| @config.excluded_file?(p) }.map { |path| { path: path } }
      # paths = paths.map { |path| { path: path } }

      if paths.empty?
        Guard::Compat::UI.info 'Guard has not detected any valid changes.  Skipping run'
        return
      end

      if paths.size == 1 && paths[0] == stylelint_config_file
        Guard::Compat::UI.info 'Detected a change to the stylelint config file only.  Running Guard on all scss files'
        run_all
        return
      end

      paths = paths.reject { |p| p == stylelint_config_file }.uniq
      Guard::Compat::UI.info "Running Stylelint on #{paths}"
      run paths
    end

    private

    def stylelint_config_file
      @stylelint_config_file ||= begin
        basename = ".stylelintrc"
        ext = [ ".json", ".yaml", ".yml", ".js", "" ].find do |ext|
          ::File.exist?("#{basename}#{ext}")
        end
        "#{basename}#{ext}"
      end
    end

    def run(paths = [])
      pid = spawn({}, "npx", "stylelint", *paths)
      Process.waitpid2(pid)
    end
  end
end
