class Gws::Group
  class << self
    def root
      @root ||= "#{Rails.root}/tmp/#{unique_id}/gws"
    end
  end
end

RSpec.configuration.after(:suite) do
  ::FileUtils.rm_rf Gws::Group.root if ::Dir.exist?(Gws::Group.root)
end
