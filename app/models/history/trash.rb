class History::Trash
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission

  store_in_repl_master
  index({ created: -1 })

  field :version, type: String, default: SS.version
  field :ref_coll, type: String
  field :ref_class, type: String
  field :data, type: Hash

  validates :ref_coll, presence: true
  validates :data, presence: true

  def model
    ref_class.constantize
  end

  def parent
    path = File.dirname(data[:filename])
    History::Trash.where('data.filename' => path, 'data.site_id' => data[:site_id]).first
  end

  def restore(save = false)
    attributes = data.dup
    attributes[:state] = 'closed'
    attributes.each do |k, v|
      if model.relations[k].present?
        if model.relations[k].class == Mongoid::Association::Embedded::EmbedsMany
          attributes[k] = attributes[k].collect do |relation|
            if relation['_type'].present?
              relation = relation['_type'].constantize.new(relation)
            else
              relation = model.relations[k].class_name.constantize.new(relation)
            end
            relation.fields.each do |key, field|
              if field.type == SS::Extensions::ObjectIds
                klass = field.options[:metadata][:elem_class].constantize
                next unless klass.include?(SS::Model::File)
                relation[key].each_with_index do |file_id, i|
                  relation[key][i] = restore_file(file_id)
                end
              else
                klass = field.association.class_name.constantize rescue nil
                next if klass.blank?
                next unless klass.include?(SS::Model::File)
                relation[key] = restore_file(relation[key])
              end
            end
            relation
          end
        end
      elsif model.fields[k].present?
        if model.fields[k].type == SS::Extensions::ObjectIds
          klass = model.fields[k].options[:metadata][:elem_class].constantize
          next unless klass.include?(SS::Model::File)
          attributes[k] = attributes[k].collect do |file_id|
            restore_file(file_id)
          end
        else
          klass = model.fields[k].association.class_name.constantize rescue nil
          next if klass.blank?
          next unless klass.include?(SS::Model::File)
          attributes[k] = restore_file(v)
        end
      end
    end
    item = model.find_or_initialize_by(_id: data[:_id], site_id: data[:site_id])
    item = item.becomes_with_route(data[:route]) if data[:route].present?
    if model.include?(Cms::Content) && data[:depth] > 1
      dir = ::File.dirname(data[:filename]).sub(/^\.$/, "")
      item_parent = Cms::Node.where(site_id: data[:site_id], filename: dir).first
      item.errors.add :base, :not_found_parent_node if item_parent.blank?
    end
    attributes.each do |k, v|
      item[k] = v
    end
    if item.respond_to?(:in_file)
      path = "#{Rails.root}/private/trash/#{item.path.sub(/.*\/(ss_files\/)/, '\\1')}"
      if File.exist?(path)
        file = Fs::UploadedFile.create_from_file(path, content_type: item.content_type)
      else
        file = Fs::UploadedFile.new("ss_trash")
        file.original_filename = 'dummy'
      end
      item.in_file = file
    end
    if save
      if item.errors.blank? && item.save
        self.destroy
      else
        errors.add :base, item.errors.full_messages
        return false
      end
    end
    item
  end

  def restore!
    self.restore(true)
  end

  class << self
    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], 'data.name', 'data.filename', 'data.html'
      end
      if params[:ref_coll] == 'all'
        criteria = criteria.nin(ref_coll: 'ss_files')
      elsif params[:ref_coll].present?
        criteria = criteria.where(ref_coll: params[:ref_coll])
      end
      criteria
    end
  end

  private

  def restore_file(file_id)
    file = self.class.where(ref_coll: 'ss_files', 'data._id' => file_id).first
    if file.present?
      file = save ? file.restore! : file.restore
    end
    return if file.blank?
    return unless save
    path = "#{Rails.root}/private/trash/#{file.path.sub(/.*\/(ss_files\/)/, '\\1')}"
    return unless File.exist?(path)
    FileUtils.mkdir_p(File.dirname(file.path))
    FileUtils.cp(path, file.path)
    FileUtils.rm_rf(File.dirname(path))
    file._id
  end
end
