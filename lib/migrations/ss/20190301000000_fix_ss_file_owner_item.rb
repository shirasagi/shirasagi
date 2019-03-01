class SS::Migration20190301000000
  def change
    # load all models
    ::Rails.application.eager_load!

    all_ids = SS::File.all.exists(owner_item_id: false).pluck(:id).sort
    all_ids.each_slice(20) do |ids|
      SS::File.all.in(id: ids).to_a.each do |file|
        file = file.becomes_with_model
        next if file.is_a?(SS::ThumbFile) || file.try(:thumb?)
        next if !file.respond_to?(:owner_item)
        next if file.owner_item_id

        file.owner_item = find_owner_item(file)
        file.model = file.owner_item_type if file.owner_item_type.present?
        file.save!
      end
    end
  end

  def find_owner_item(file)
    ::Mongoid.models.each do |model|
      # skip if model is one of file models
      next if model.ancestors.include?(SS::Model::File)
      next if !model.ancestors.include?(SS::Document)

      item = find_owner_item_in(file, model)
      return item if item
    end

    nil
  end

  def find_owner_item_in(file, model)
    # puts model
    model.fields.each do |field_name, field_config|
      if field_config.type.ancestors.include?(SS::Model::File)
        item = find_owner_item_in_scalar_field(file, model, field_name)
        return item if item
        next
      end

      if field_config.association && field_config.association.class_name
        type = field_config.association.class_name.constantize rescue nil
        if type && type.ancestors.include?(SS::Model::File)
          item = find_owner_item_in_association_field(file, model, field_name)
          return item if item
          next
        end
      end

      if field_config.options && field_config.options.dig(:metadata, :elem_class)
        type = field_config.options.dig(:metadata, :elem_class).constantize rescue nil
        if type && type.ancestors.include?(SS::Model::File)
          item = find_owner_item_in_array_field(file, model, field_name)
          return item if item
          next
        end
      end
    end

    model.embedded_relations.each do |relation_name, relation_config|
      if relation_name == "column_values"
        item = find_owner_item_in_column_values(file, model, relation_name)
        return item if item
        next
      end
    end

    nil
  end

  def find_owner_item_in_scalar_field(file, model, field_name)
    model.all.where(field_name => file.id).first
  end

  def find_owner_item_in_association_field(file, model, field_name)
    model.all.where(field_name => file.id).first
  end

  def find_owner_item_in_array_field(file, model, field_name)
    model.all.in(field_name => file.id).first
  end

  def find_owner_item_in_column_values(file, model, relation_name)
    conds = [{ "column_values.file_ids" => file.id }, { "column_values.file_id" => file.id }]
    model.all.where("$and" => [{ "$or" => conds }]).first
  end
end
