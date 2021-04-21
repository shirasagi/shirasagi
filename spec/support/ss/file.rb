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

  SS::Application.private_root = root_dir

  # backward compatibility
  all_models = ::Mongoid.models
  models = all_models.select { |model| model.respond_to?(:root=) && model.root.to_s.start_with?("#{Rails.root}/") }
  models.each do |model|
    model.root = root_dir
  end
end

RSpec.configuration.after(:suite) do
  clear_files
end
