module Chorg::MongoidSupport
  include Chorg::Context
  include Chorg::Loggable

  def update_attributes(entity, hash)
    hash.select { |k, v| v.present? }.each { |k, v| entity[k] = v }
    entity
  end

  def replace_attributes(entity, hash)
    entity.attributes = hash
    entity
  end

  def copy_attributes_deeply(entity)
    hash = {}
    entity.attributes.each do |k, v|
      hash[k] = v
    end
    hash
  end

  def with_all_entity_updates(models, substituter)
    with_all_entities(models) do |entity|
      with_updates(entity, substituter) do |updates|
        yield entity, updates
      end
    end
  end

  def with_all_entities(models)
    models.each do |model|
      model.each do |entity|
        entity = entity.try(:becomes_with_route) || entity
        entity.try(:cur_site=, @cur_site)
        entity.try(:cur_user=, @cur_user) if @cur_user.present?
        entity.try(:allow_other_user_files)
        yield entity
      end
    end
  end

  def find_or_create_group(attributes)
    group = Cms::Group.where(name: attributes["name"]).first
    group ||= Cms::Group.create
    update_attributes(group, attributes)
  end

  GROUP_CLASSES = [ SS::Group, Cms::Group, Sys::Group ].freeze

  def group_field?(_, v)
    type = v.options[:type]
    if GROUP_CLASSES.include?(type)
      return true
    end

    metadata = v.options[:metadata]
    return false if metadata.blank?

    classes = [:class_name, :elem_class].map do |k|
      v = metadata[k]
      v = v.constantize if v.present?
      v
    end.compact
    classes.select { |v| GROUP_CLASSES.include?(v) }.present?
  end

  def build_exclude_fields(defs)
    @exclude_fields = defs.map { |e| e.start_with?("/") && e.end_with?("/") ? /#{Regexp.escape(e[1..-2])}/ : e }.freeze
  end

  def updatable_field?(k, v)
    field_type = v.options[:type]
    return false unless String == field_type

    @exclude_fields.each do |filter|
      if filter.is_a?(Regexp)
        return false if filter =~ k
      elsif k == filter
        return false
      end
    end
    true
  end

  def target_fields_cache
    @target_fields_cache ||= []
  end

  def target_fields(entity)
    return target_fields_cache[1] if target_fields_cache[0] == entity.class

    target_fields_cache[0] = entity.class
    target_fields_cache[1] = entity.class.fields.select { |k, v| group_field?(k, v) || updatable_field?(k, v) }.to_a
    target_fields_cache[1]
  end

  def with_updates(entity, substituter)
    updates = {}
    target_fields(entity).each do |k, _|
      v = entity[k]
      next if v.blank?
      new_value = substituter.call(v)
      updates[k] = new_value if v != new_value
    end

    yield updates
  end

  def delete_groups(group_ids)
    group_ids.each do |id|
      group = Cms::Group.where(id: id).first
      if group.present?
        if delete_entity(group)
          put_log("deleted group: #{group.name}")
        else
          put_log("failed to delete group: #{group.name}")
        end
        remove_group_from_site(group)
      end
    end
  end

  def add_group_to_site(group)
    return unless adds_group_to_site
    return if group.id == 0
    return if cur_site.group_ids.include?(group.id)

    copy = Array.new(cur_site.group_ids)
    copy << group.id
    cur_site.group_ids = copy.uniq.sort
    if save_or_collect_errors(cur_site)
      put_log("added group #{group.name} to site #{cur_site.host}")
    else
      put_log("failed to add group #{group.name} to site #{cur_site.host}")
    end
  end

  def remove_group_from_site(group)
    return unless cur_site.group_ids.include?(group.id)

    copy = Array.new(cur_site.group_ids)
    copy.delete(group.id)
    cur_site.group_ids = copy.uniq.sort
    if save_or_collect_errors(cur_site)
      put_log("removed group #{group.name} from site #{cur_site.host}")
    else
      put_log("failed to remove group #{group.name} from site #{cur_site.host}")
    end
  end

  def convert_to_group_names(group_ids)
    group_ids.map do |group_id|
      if group_id == 0
        I18n.t("chorg.messages.test_run")
      else
        group = Cms::Group.where(id: group_id).first
        group.present? ? group.name : nil
      end
    end.compact
  end
end
