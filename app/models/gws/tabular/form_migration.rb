class Gws::Tabular::FormMigration
  include ActiveModel::Model

  attr_accessor :shirasagi, :site_id, :form_id, :release_id, :revision_changes

  def add_column(field_name, type:, **options)
  end

  def change_column(field_name, changes:, **options)
    prev_attrs = changes[0].then { Base64.strict_decode64(_1) }
                            .then { BSON::ByteBuffer.new(_1) }
                            .then { Hash.from_bson(_1) }
    current_attrs = changes[1].then { Base64.strict_decode64(_1) }
                            .then { BSON::ByteBuffer.new(_1) }
                            .then { Hash.from_bson(_1) }

    if prev_attrs["index_state"] != current_attrs["index_state"] && prev_attrs["index_state"] == "enabled"
      @drop_indexes ||= []
      @drop_indexes << { field_name => 1 }
    end

    converter = retrieve_converter(field_name, prev_attrs, current_attrs)
    if converter
      @converter_map ||= {}
      @converter_map[field_name] = converter
    end

    current_type = current_attrs["_type"]
    if current_type == Gws::Tabular::Column::FileUploadField.name && prev_attrs["export_state"] != current_attrs["export_state"]
      @publish_files ||= []
      if current_attrs["export_state"] == "public"
        @publish_files << [ field_name, "publish" ]
      else
        @publish_files << [ field_name, "depublish" ]
      end
    end
  end

  def delete_column(field_name, type:, **options)
    @drop_columns ||= []
    @drop_columns << [ field_name, type ]
    if type == Gws::Tabular::Column::LookupField.name
      @drop_columns << [ "#{field_name}_spec", type ]
    end
  end

  def call
    @form = Gws::Tabular::Form.find(form_id)
    @release = Gws::Tabular::FormRelease.find(release_id)
    @file_model = Gws::Tabular::File[@release]

    drop_indexes
    drop_columns
    migrate_columns
    public_or_depublic_files

    @file_model.create_indexes
  end

  private

  def form
    @form ||= Gws::Tabular::Form.find(form_id)
  end

  def retrieve_converter(field_name, lhs_changes, rhs_changes)
    case rhs_changes["_type"]
    when Gws::Tabular::Column::TextField.name
      if rhs_changes["i18n_state"] == "enabled"
        ToI18nConverter.new(field_name: field_name, default_value: rhs_changes["i18n_default_value"].presence)
      else
        ToTextConverter.new(field_name: field_name, default_value: rhs_changes["i18n_default_value"].presence)
      end
    when Gws::Tabular::Column::NumberField.name
      case rhs_changes["field_type"]
      when "float"
        # nothing
      when "decimal"
        # nothing
      else # "integer"
        ToIntConverter.new(field_name: field_name, default_value: rhs_changes["default_value"].presence)
      end
    end
  end

  def drop_indexes
    return unless @drop_indexes

    @drop_indexes.each do |index_spec|
      @file_model.collection.indexes.drop_one(index_spec)
    end
  end

  def drop_columns
    return unless @drop_columns

    @drop_columns.each do |field_name, type|
      if type == Gws::Tabular::Column::FileUploadField.name
        file_ids = @file_model.all.pluck(field_name)
        file_ids.compact!
        file_ids.uniq!
      end

      @file_model.unscoped.unset(field_name)

      next if file_ids.blank?

      ::SS::File.each_file(file_ids) do |file|
        file.destroy
      end

      @file_model.collection.indexes.drop_one({ field_name => 1 }) rescue nil
    end
  end

  def migrate_columns
    return unless @converter_map

    @converter_map.each do |_key, converter|
      converter.before_collection(@file_model.collection)
    end

    projection = { _id: 1 }
    @converter_map.keys.each { |key| projection[key] = 1 }
    docs = @file_model.collection.find({}, { projection: projection, allow_disk_use: true }).to_a

    write_operations = []
    docs.each do |doc|
      updates = {}
      migration_errors = []
      @converter_map.each do |key, converter|
        converter.before_document(doc)

        if doc.key?(key)
          updates[key] = converter.call(doc[key])
          if converter.errors.present?
            migration_errors += converter.errors.full_messages
          end
        end

        converter.after_document(doc)
      end

      next if updates.blank?

      write_operation = { update_one: { filter: { _id: doc["_id"] }, update: { "$set" => updates } } }
      if migration_errors.present?
        write_operation[:update_one][:update]["$push"] = { migration_errors: { "$each" => migration_errors } }
      end

      write_operations << write_operation
      flush_write_operations(write_operations) if write_operations.length >= 100
    end
    flush_write_operations(write_operations)

    @converter_map.each do |_key, converter|
      converter.after_collection(@file_model.collection)
    end
  end

  def flush_write_operations(write_operations)
    return write_operations if write_operations.blank?

    @file_model.collection.bulk_write(write_operations)
    write_operations.clear
  end

  def public_or_depublic_files
    return if @publish_files.blank?

    publishes = []
    depublishes = []
    @publish_files.each do |field_name, operation|
      if operation == "publish"
        publishes << field_name
      else
        depublishes << field_name
      end
    end

    job_class = ::Gws::Tabular::File::PublishUploadFileJob.bind(site_id: site_id)
    job_class.perform_later(form.space_id.to_s, form_id.to_s, release_id.to_s, publishes.presence, depublishes.presence)
  end
end
