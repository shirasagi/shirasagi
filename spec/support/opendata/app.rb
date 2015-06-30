RSpec.configuration.before(:suite) do
  # override zip_dir method to write zip file to tmp dir
  class Opendata::App
    class << self
      alias_method :zip_dir_orig, :zip_dir
      @@tmp_dir = Pathname(::Dir.mktmpdir)
      def zip_dir
        @@tmp_dir
      end
    end
  end
end

RSpec.configuration.after(:suite) do
  FileUtils.rm_rf(Opendata::App.zip_dir)
end
