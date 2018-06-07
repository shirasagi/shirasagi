class SS::File
  include SS::Model::File
  include SS::Relation::Thumb

  cattr_accessor(:models, instance_accessor: false) { [] }

  class << self
    def model(model, klass)
      self.models << [ model, klass ]
    end

    def find_model_class(model)
      klass = SS::File.models.find { |k, v| k == model }
      klass = klass[1] if klass
      klass
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
