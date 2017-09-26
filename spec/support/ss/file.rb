def root_dir
  "#{Rails.root}/tmp/ss_files"
end

def clear_files
  ::Fs.rm_rf(root_dir)
  ::Fs.mkdir_p(root_dir)
end

RSpec.configuration.before(:suite) do
  # load all models
  ::Rails.application.eager_load!

  clear_files

  models = ::Mongoid.models
  models = models.select { |model| model.ancestors.include?(::SS::Model::File) }
  models.each do |model|
    model.root = root_dir
  end
end
