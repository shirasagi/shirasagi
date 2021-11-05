class SS::Migration20190320000000
  include SS::Migration::Base

  depends_on "20190314000000"

  def change
    # load all models
    ::Rails.application.eager_load!

    conds = [{ :owner_item_id.exists => false }, { owner_item_id: 0 }]
    all_ids = SS::File.unscoped.where("$and" => [{ "$or" => conds}]).pluck(:id).sort
    all_ids.each_slice(20) do |ids|
      SS::File.unscoped.in(id: ids).to_a.each do |file|
        file = file.becomes_with_model
        next if file.model == "ss/thumb_file" || file.try(:thumb?)
        next if !file.respond_to?(:owner_item)
        owner_item = file.owner_item rescue nil
        next if owner_item.present?

        owner_item = file.owner_item = normalize_item(find_owner_item(file))
        next if owner_item.blank?

        file.model = owner_item.model_name.i18n_key.to_s
        if file.model == "gws/memo/message" && file.site.blank?
          file.site = owner_item.site
        end

        if file.content_type.blank?
          file.content_type = "application/octet-stream"
        end

        unless file.save
          STDERR.puts "ファイル #{file.name}(#{file.id};#{file.model}) でエラーが発生しました。"
          STDERR.puts file.errors.full_messages.join("\n")
        end
      end
    end
  end

  def find_owner_item(file)
    ::Mongoid.models.each do |model|
      # skip if model is one of file models
      next if model.ancestors.include?(SS::Model::File)
      next if !model.ancestors.include?(SS::Document)

      item = find_owner_item_in(file, model, model.all, [])
      return item if item
    end

    nil
  end

  def find_owner_item_in(file, model, criteria, prefixes)
    # puts model
    model.fields.each do |field_name, field_config|
      if field_config.type.ancestors.include?(SS::Model::File)
        item = find_owner_item_in_scalar_field(file, criteria, prefixes, field_name)
        return item if item
        next
      end

      if field_config.association && field_config.association.class_name
        type = field_config.association.class_name.constantize rescue nil
        if type && type.ancestors.include?(SS::Model::File)
          item = find_owner_item_in_association_field(file, criteria, prefixes, field_name)
          return item if item
          next
        end
      end

      if field_config.options && field_config.options.dig(:metadata, :elem_class)
        type = field_config.options.dig(:metadata, :elem_class).constantize rescue nil
        if type && type.ancestors.include?(SS::Model::File)
          item = find_owner_item_in_array_field(file, criteria, prefixes, field_name)
          return item if item
          next
        end
      end
    end

    model.embedded_relations.each do |relation_name, relation_config|
      if relation_name == "column_values" || relation_name == "facility_column_values"
        item = find_owner_item_in_column_values(file, model, prefixes, relation_name)
        return item if item
      else
        item = find_owner_item_in(file, relation_config.klass, criteria, prefixes + [relation_name])
        return item if item
      end
    end

    nil
  end

  def find_owner_item_in_scalar_field(file, criteria, prefixes, field_name)
    criteria.where(build_criteria_key(prefixes, field_name) => file.id).first
  end

  def find_owner_item_in_association_field(file, criteria, prefixes, field_name)
    criteria.where(build_criteria_key(prefixes, field_name) => file.id).first
  end

  def find_owner_item_in_array_field(file, criteria, prefixes, field_name)
    criteria.in(build_criteria_key(prefixes, field_name) => file.id).first
  end

  def build_criteria_key(*keys)
    keys.flatten.join(".")
  end

  def find_owner_item_in_column_values(file, model, prefixes, field_name)
    conds = [
      { build_criteria_key(prefixes, field_name, "file_ids") => file.id },
      { build_criteria_key(prefixes, field_name, "file_id") => file.id }
    ]
    model.all.where("$and" => [{ "$or" => conds }]).first
  end

  def normalize_item(item)
    return if item.blank?

    item
  end
end
