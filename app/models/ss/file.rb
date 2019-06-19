class SS::File
  include SS::Model::File
  include SS::Relation::Thumb
  include SS::Liquidization

  cattr_accessor(:models, instance_accessor: false) { [] }

  liquidize do
    export :name
    export :extname
    export :size
    export :humanized_name
    export :filename
    export :basename
    export :url
    export :thumb_url
    export :image?
  end

  class << self
    def model(model, klass, metadata = {})
      self.models << [ model, klass, metadata ]
    end

    def find_model_class(model)
      config = SS::File.models.find { |k, v| k == model }
      klass = config[1] if config
      klass
    end

    def find_model_metadata(model)
      config = SS::File.models.find { |k, v| k == model }
      metadata = config[2] if config
      metadata
    end
  end

  def remove_file
    backup = History::Trash.new
    backup.ref_coll = collection_name
    backup.ref_class = self.class.to_s
    backup.data = attributes
    backup.site = self.site
    backup.save
    trash_path = "#{Rails.root}/private/trash/#{path.sub(/.*\/(ss_files\/)/, '\\1')}"
    FileUtils.mkdir_p(File.dirname(trash_path))
    FileUtils.cp(path, trash_path)
    super
  end
end
