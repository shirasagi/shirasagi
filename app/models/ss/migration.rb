class SS::Migration
  extend SS::Translation
  include SS::Document

  field :version, type: String

  DIR = Rails.root.join('lib/migrations')

  class << self
    # Do migration.
    def migrate
      filepath_list = filepaths_to_apply
      if version = ENV["VERSION"]
        filepath_list = filepath_list.select { |filepath| take_timestamp(filepath) <= version }
      end

      apply_all(filepath_list, check_dependency: ENV["CHECK_DEPENDENCY"])
    end

    def up
      version = ENV["VERSION"]
      if version.blank?
        puts "VERSION is missing"
        puts "rake ss:migrate:up VERSION=<VERSION TO APPLY>"
        return
      end

      unless ENV["FORCE"]
        db_list = order(version: 1).pluck(:version).uniq.select(&:present?)
        if db_list.include?(version)
          puts "VERSION '#{version}' was already applied"
          return
        end
      end

      filepath_list = filepaths.select { |filepath| take_timestamp(filepath) == version }
      if filepath_list.blank?
        puts "VERSION '#{version}' is not found"
        return
      end

      apply_all(filepath_list, check_dependency: ENV["CHECK_DEPENDENCY"], force: ENV["FORCE"])
    end

    def status
      db_list = order(version: 1).pluck(:version).uniq.select(&:present?)

      file_list = filepaths.map { |filepath| parse_migration_filename(filepath) }.group_by { |version, _| version }
      file_list = file_list.map do |version, version_name_pairs|
        status = db_list.delete(version) ? "up" : "down"
        names = version_name_pairs.map { |_version, name| name }
        names.flatten!
        [ status, version, names ]
      end

      db_list.map! { |version| [ 'up', version, [ "********** NO FILE **********" ] ] }

      puts
      puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
      puts "-" * 50
      (db_list + file_list).sort_by { |_, version, _| version }.each do |status, version, names|
        puts "#{status.center(8)}  #{version.ljust(14)}  #{names.join(", ")}"
      end
      puts
    end

    # Return the all filepaths in *RAILS_ROOT/lib/migrations/**.
    #
    # Returned array is sorted ascending by the filename.
    #
    # @return [Array<String>] An array of sorted filepathe strings.
    #
    # @example It returns an array of filepath strings.
    #   # Directory structure
    #
    #   # + /foo/bar/lib/migrations/
    #   #   + mod1/
    #   #     - 20150324000001_a.rb
    #   #     - 20150324000002_a.rb
    #   #   + mod2/
    #   #     - 20150324000000_a.rb
    #   #     - 20150324000003_a.rb
    #
    #   SS::Migration.filepaths
    #   #=>
    #   # ['/foo/bar/lib/migrations/mod2/20150324000000_a.rb',
    #   #  '/foo/bar/lib/migrations/mod1/20150324000001_a.rb',
    #   #  '/foo/bar/lib/migrations/mod1/20150324000002_a.rb',
    #   #  '/foo/bar/lib/migrations/mod2/20150324000003_a.rb',]
    def filepaths
      ::Dir.glob(DIR.join('*/*.rb')).sort_by { |i| parse_migration_filename(i) }
    end

    # Returns the latest applied migration version string.
    # If there is no applied migration, it returns "00000000000000".
    #
    # @return [String] The latest applied migration version string or "00000000000000".
    #
    # @example
    #   SS::Migration.latest_version #=> '20150330000000'
    def latest_version
      x = order(version: -1).limit(1).first
      x.nil? ? '00000000000000' : x.version
    end

    def parse_migration_filename(filepath)
      File.basename(filepath, ".*").split('_', 2)
    end

    # Take a timestamp from a filepath.
    #
    # @param [String] filepath
    #
    # @return [String] timestamp
    #
    # @example
    #   SS::Migration.take_timestamp '/foo/bar/lib/migrations/mod1/20150330000000_a.rb'
    #   #=> '20150330000000'
    def take_timestamp(filepath)
      version, _name = parse_migration_filename(filepath)
      version
    end

    # Return the all filepath of migrations to apply.
    #
    # It is a sub array of *filepaths* method.
    #
    # @return [Array<String>] An array of filepath of migrations to apply.
    def filepaths_to_apply
      filepaths.select { |e| take_timestamp(e) > latest_version }
    end

    def latest_migration_file_version
      latest = filepaths.map { |e| take_timestamp(e) }.max
      latest || '00000000000000'
    end

    def new_version
      latest = latest_migration_file_version
      latest_ymd_part = latest[0..7]
      latest_seq_part = latest[8..-1]

      current_ymd_part = Time.zone.now.strftime("%Y%m%d")

      if current_ymd_part > latest_ymd_part
        ymd_part = current_ymd_part
        seq = 0
      else
        ymd_part = latest_ymd_part
        seq = latest_seq_part.to_i + 1
      end

      "#{ymd_part}#{seq.to_s.rjust(6, "0")}"
    end

    private

    def apply_all(filepath_list, context)
      filepath_list.each { |filepath| apply(filepath, context) }
    end

    def apply(filepath, context)
      context[:versions_have_been_run] ||= []

      timestamp, name = parse_migration_filename filepath
      require filepath
      klass = "SS::Migration#{timestamp}".constantize
      missing_versions = non_applied_dependent_versions(klass, context)
      if missing_versions.present?
        puts "Error SS::Migration#{timestamp} (#{name}) is required #{missing_versions.join(", ")}"
        return
      end

      if context[:check_dependency]
        context[:versions_have_been_run] << timestamp
        puts "Applied SS::Migration#{timestamp}"
        return
      end

      klass.new.change
      item = where(version: timestamp).first_or_initialize
      item.updated = Time.zone.now
      item.save!
      puts "Applied SS::Migration#{timestamp}"
    end

    def non_applied_dependent_versions(klass, context)
      return [] if !klass.respond_to?(:depends)
      return [] if klass.depends.blank?

      klass.depends.select do |version|
        next false if context[:versions_have_been_run].include?(version)
        next false if unscoped.where(version: version).present?

        true
      end
    end
  end
end
