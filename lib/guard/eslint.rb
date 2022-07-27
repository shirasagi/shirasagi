require 'guard/compat/plugin'
require 'rainbow'

module Guard
  class Eslint < Plugin
    attr_reader :options, :config

    def self.non_namespaced_name
      'eslint'
    end

    def initialize(options = {})
      super

      @options = { all_on_start: true }.merge(options)
    end

    def start
      Guard::Compat::UI.info "Guard::Eslint is running"
      run_all if @options[:all_on_start]
    end

    def reload
    end

    def run_all
      Guard::Compat::UI.info 'Running Eslint for all .js files'
      files = Dir.glob("**/*.js")
      files += Dir.glob("**/*.js.erb")
      paths = Guard::Compat.matching_files(self, files)
      run_on_changes paths
    end

    def run_on_changes(paths)
      if paths.empty?
        Guard::Compat::UI.info 'Guard has not detected any valid changes.  Skipping run'
        return
      end

      if paths.size == 1 && paths[0] == eslint_config_file
        Guard::Compat::UI.info 'Detected a change to the eslint config file only.  Running Guard on all js files'
        run_all
        return
      end

      paths = paths.reject { |p| p == eslint_config_file }.uniq
      Guard::Compat::UI.info "Running Eslint on #{paths}"
      run paths
    end

    private

    def eslint_config_file
      @eslint_config_file ||= begin
        basename = ".eslintrc"
        ext = [ ".json", ".yaml", ".yml", ".js", "" ].find do |ext|
          ::File.exist?("#{basename}#{ext}")
        end
        "#{basename}#{ext}"
      end
    end

    def run(paths = [])
      pid = spawn({}, "npx", "eslint", *paths)
      Process.waitpid2(pid)
    end
  end
end
