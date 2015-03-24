class SS::Migration
  DIR = Rails.root.join('lib/migrations')

  class << self
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
      ::Dir.glob(DIR.join('*/*')).sort_by { |i| File.basename i }
    end
  end
end
