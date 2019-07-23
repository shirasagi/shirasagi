class History::Backup
  include SS::Document
  include SS::Reference::User

  store_in_repl_master
  index({ ref_coll: 1, "data._id" => 1, created: -1 })

  cattr_reader(:max_age) { 20 }

  field :version, type: String, default: SS.version
  field :ref_coll, type: String
  field :ref_class, type: String
  field :data, type: Hash
  field :state, type: String

  validates :ref_coll, presence: true
  validates :data, presence: true

  def coll
    collection.database[ref_coll]
  end

  def ref_class_constantize
    models = Mongoid.models.reject { |m| m.to_s.start_with?('Mongoid::') }
    models.find{ |m| m.to_s == ref_class }
  end

  def ref_item
    @_ref_item ||= ref_class_constantize.find(data["_id"])
  end

  def get
    item = ref_item
    if item.current_backup
      item.current_backup.data
    else
      item.backups.first.data
    end
  end

  def restorable?
    return false if get == data

    item = ref_item
    if item.respond_to?(:state)
      item.state != "public"
    else
      true
    end
  end

  def restore
    data  = self.data.dup
    query = coll.find _id: data["_id"]
    if query.count != 1
      errors.add :base, "#{query.count} documents were found."
      return false
    end

    data.delete("_id")
    data.delete("state")

    ref_class_constantize.relations.each do |k, relation|
      case relation.class.to_s
      when Mongoid::Association::Embedded::EmbedsMany.to_s
        next if data[k].blank?
        data[k] = data[k].collect do |relation|
          if relation['_type'].present?
            klass = relation['_type'].constantize.new(relation)
          else
            klass = ref_class_constantize.relations[k].class_name.constantize.new(relation)
          end
          klass.fields.each do |key, field|
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
    end
    ref_class_constantize.fields.each do |k, field|
      next if data[k].blank?
      if field.type == SS::Extensions::ObjectIds
        klass = field.options[:metadata][:elem_class].constantize
        next unless klass.include?(SS::Model::File)
        data[k] = data[k].collect do |file_id|
          restore_file(file_id)
        end
      else
        klass = field.association.class_name.constantize rescue nil
        next if klass.blank?
        next unless klass.include?(SS::Model::File)
        data[k] = restore_file(data[k])
      end
    end

    begin
      query.update_many('$set' => data)
      item = ref_class.constantize.find(self.data["_id"])
      current = item.current_backup
      before = item.before_backup

      self.state = 'current'
      current.state = 'before' if current
      before.state = nil if before

      self.update
      current.update if current
      before.update if before

      return true
    rescue => e
      errors.add :base, "error. #{e}"
      return false
    end
  end

  def restore_file(file_id)
    file = SS::File.where(id: file_id).first
    return file.id if file.present?
    file = History::Trash.where(ref_coll: 'ss_files', 'data._id' => file_id).first
    file = file.restore!
    return if file.blank?
    path = "#{Rails.root}/private/trash/#{file.path.sub(/.*\/(ss_files\/)/, '\\1')}"
    return unless File.exist?(path)
    FileUtils.mkdir_p(File.dirname(file.path))
    FileUtils.cp(path, file.path)
    FileUtils.rm_rf(File.dirname(path))
    file._id
  end
end
