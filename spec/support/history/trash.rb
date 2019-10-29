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

  super_classes = [ ::History::Model::Data ]

  all_models = ::Mongoid.models
  super_classes.each do |super_class|
    models = all_models.select { |model| model.ancestors.include?(super_class) }
    models.each do |model|
      model.root = "#{root_dir}/trash"
    end
  end
end

RSpec.configuration.after(:suite) do
  clear_files
end
