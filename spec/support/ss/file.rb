def root_dir
  "#{Rails.root}/tmp/rspec-#{Process.pid}"
end

def clear_files
  ::Fs.rm_rf(root_dir)
end

RSpec.configuration.before(:suite) do
  # load all models
  ::Rails.application.eager_load!

  ::Fs.mkdir_p(root_dir)

  all_models = ::Mongoid.models
  models = all_models.select { |model| model.ancestors.include?(::SS::Model::File) }
  models.each do |model|
    model.root = "#{root_dir}/files"
  end

  SS::DownloadJobFile.root = "#{root_dir}/download"
end

RSpec.configuration.after(:suite) do
  clear_files
end
