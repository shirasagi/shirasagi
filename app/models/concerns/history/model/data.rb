module History::Model::Data
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  included do
    store_in_repl_master
    index({ created: -1 })
    index({ ref_coll: 1, "data._id" => 1, created: -1 })

    cattr_reader(:max_age) { SS.config.ss.history_max_age || 20 }

    field :version, type: String, default: SS.version
    field :ref_coll, type: String
    field :ref_class, type: String
    field :data, type: Hash
    field :state, type: String

    validates :ref_coll, presence: true
    validates :data, presence: true
  end

  module ClassMethods
    def root
      "#{SS::Application.private_root}/trash"
    end
  end

  def coll
    collection.database[ref_coll]
  end

  def model
    return if ref_class.blank? || ref_class.start_with?('Mongoid::')
    @model ||= ref_class.constantize rescue nil
  end

  private

  def restore_data(data, opts = {})
    model.relations.each do |k, relation|
      case relation.class.to_s
      when Mongoid::Association::Referenced::HasMany.to_s
        if relation.dependent.present? && opts[:create_by_trash].present?
          History::Trash.where(ref_class: relation.class_name, "data.#{relation.foreign_key}" => data['_id']).restore!(opts)
        end
      when Mongoid::Association::Embedded::EmbedsMany.to_s
        next if data[k].blank?

        data[k] = data[k].collect do |relation|
          if relation['_type'].present?
            klass = relation['_type'].constantize.new(relation)
          else
            klass = model.relations[k].class_name.constantize.new(relation)
          end
          klass.fields.each do |key, field|
            if field.type == SS::Extensions::ObjectIds
              klass = field.options[:metadata][:elem_class].constantize

              next unless klass.include?(SS::Model::File)

              relation[key].each_with_index do |file_id, i|
                relation[key][i] = restore_file(file_id, opts)
              end
            else
              klass = field.association.class_name.constantize rescue nil

              next if klass.blank? || !klass.include?(SS::Model::File)

              relation[key] = restore_file(relation[key], opts)
            end
          end
          relation
        end
      end
    end
    model.fields.each do |k, field|
      next if %w(_id state).include?(k)
      data[k] = nil if data[k].blank?
      next if data[k].nil?

      if field.type == SS::Extensions::ObjectIds
        klass = field.options[:metadata][:elem_class].constantize

        next unless klass.include?(SS::Model::File)

        data[k] = data[k].collect do |file_id|
          restore_file(file_id, opts)
        end
      else
        klass = field.association.class_name.constantize rescue nil

        next if klass.blank? || !klass.include?(SS::Model::File)

        data[k] = restore_file(data[k], opts)
      end
    end
    data
  end

  def restore_file(file_id, opts = {})
    file = SS::File.where(id: file_id).first

    return file.id if file.present?
    return unless opts[:create_by_trash]

    file = History::Trash.where(ref_coll: 'ss_files', 'data._id' => file_id).first
    file = file.restore(opts) if file.present?

    return if file.blank?

    path = "#{History::Trash.root}/#{file.path.sub(/.*\/(ss_files\/)/, '\\1')}"

    return file.id unless File.exist?(path)

    FileUtils.mkdir_p(File.dirname(file.path))
    FileUtils.cp(path, file.path)
    FileUtils.rm_rf(File.dirname(path))
    file.id
  end
end
