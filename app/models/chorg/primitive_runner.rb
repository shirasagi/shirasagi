module Chorg::PrimitiveRunner
  include Chorg::Context
  include Chorg::Loggable
  include Chorg::MongoidSupport

  def run_primitive_chorg
    Chorg::ChangeSet::TYPES.each do |type|
      put_log("==#{type}==")
      with_inc_depth { @item.send("#{type}_change_sets").each(&method("execute_#{type}")) }
    end
  end

  private
    def execute_add(changeset)
      put_log("add #{changeset.add_description}")
      destination = changeset.destinations.first
      group = find_or_create_group(destination)
      if save_or_collect_errors(group)
        put_log("created/updated group: #{group.name}(#{group.id})")
        inc_counter(:add, :success)
      else
        inc_counter(:add, :failed)
      end
      add_group_to_site(group)
    end

    def execute_move(changeset)
      put_log("move #{changeset.before_move} to #{changeset.after_move}")
      source = changeset.sources.first
      destination = changeset.destinations.first

      group = Cms::Group.where(id: source["id"]).first
      if group.blank?
        put_warn("group not found: #{source["name"]}(#{source["id"]})")
        return
      end

      source_attributes = copy_attributes_deeply(group)
      update_attributes(group, destination)
      if save_or_collect_errors(group)
        put_log("updated group: #{group.name}(#{group.id})")
        inc_counter(:move, :success)
        substituter.collect(source_attributes, group.attributes)
      else
        inc_counter(:move, :failed)
      end
    end

    def execute_unify(changeset)
      put_log("unify #{changeset.before_unify} to #{changeset.after_unify}")
      destination = changeset.destinations.first
      destination_group = find_or_create_group(destination)
      unless save_or_collect_errors(destination_group)
        inc_counter(:unify, :failed)
        return
      end

      put_log("created/updated group: #{destination_group.name}(#{destination_group.id})")
      inc_counter(:unify, :success)

      add_group_to_site(destination_group)

      source_groups = changeset.sources.map do |source|
        Cms::Group.where(id: source["id"]).first
      end
      source_groups = source_groups.compact
      source_groups.each do |source_group|
        substituter.collect(source_group.attributes, destination_group.attributes)
        next if source_group.id == destination_group.id
        move_users_group(source_group.id, destination_group.id)
        delete_group_ids << source_group.id
      end
    end

    def execute_division(changeset)
      put_log("division #{changeset.before_division} to #{changeset.after_division}")
      source = changeset.sources.first
      source_group = Cms::Group.where(id: source["id"]).first
      if source_group.blank?
        put_warn("group not found: #{source["name"]}")
        return
      end

      destination_groups = changeset.destinations.map do |destination|
        find_or_create_group(destination)
      end

      success = destination_groups.reduce(true) do |a, e|
        next a if e.id == source_group.id
        if save_or_collect_errors(e)
          put_log("created group: #{e.name}")
          a
        else
          false
        end
      end

      if success
        inc_counter(:division, :success)
      else
        inc_counter(:division, :failed)
        return
      end

      destination_groups.each(&method(:add_group_to_site))

      destination_group_ids = destination_groups.map(&:id).to_a
      destination_attributes = copy_attributes_deeply(destination_groups.first)
      destination_attributes["_id"] = destination_group_ids

      # be careful, user's group_ids has only first division group.
      move_users_group(source_group.id, destination_group_ids.first)
      # group of page/node/layout/part has all division groups.
      substituter.collect(source_group.attributes, destination_attributes)
      delete_group_ids << source_group.id unless destination_group_ids.include?(source_group.id)
    end

    def execute_delete(changeset)
      source_groups = changeset.sources.map do |source|
        Cms::Group.where(id: source["id"]).first
      end
      source_groups.compact.each do |source_group|
        empty_attributes = {}
        source_group.attributes.select { |_, v| v.is_a?(Fixnum) }.each { |k, v| empty_attributes[k] = v }
        validation_substituter.collect(source_group.attributes, empty_attributes)
        delete_group_ids << source_group.id
        inc_counter(:delete, :success)
      end
    end
end
