module Chorg::PrimitiveRunner
  extend ActiveSupport::Concern
  include Chorg::Context
  include Chorg::Loggable
  include Chorg::MongoidSupport
  include Gws::Chorg::NoticeSupport

  def run_primitive_chorg
    execute_before(@item.changesets)
    Chorg::Model::Changeset::TYPES.each do |type|
      # put_log("==#{type}==")
      task.log("==#{I18n.t("chorg.views.revisions/edit.#{type}")}==")
      with_inc_depth { @item.send("#{type}_changesets").each(&method("execute_#{type}")) }
    end
    execute_after(@item.changesets)
  end

  private

  def execute_add(changeset)
    put_log("add #{changeset.add_description}")
    task.log("  #{changeset.add_description}")
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
    task.log("  #{changeset.before_move} から #{changeset.after_move} へ")
    source = changeset.sources.first
    destination = changeset.destinations.first

    group = self.class.group_class.where(id: source["id"]).first
    if group.blank?
      put_warn("group not found: #{source["name"]}(#{source["id"]})")
      return
    end

    source_attributes = copy_attributes_deeply(group)
    update(group, destination)
    if save_or_collect_errors(group)
      put_log("updated group: #{group.name}(#{group.id})")
      inc_counter(:move, :success)
      substitutor.collect(source_attributes, group.attributes, [group.id])
      if destination[:contact_groups].present?
        destination_main_contact = destination[:contact_groups].find { |contact| contact[:main_state] == 'main' }
      end
      if destination_main_contact && destination_main_contact[:unifies_to_main] == 'enabled'
        unifies_contact_to_main(group, source_attributes[:_id])
      end
    else
      inc_counter(:move, :failed)
    end
  end

  def execute_unify(changeset)
    put_log("unify #{changeset.before_unify} to #{changeset.after_unify}")
    task.log("  #{changeset.before_unify} から #{changeset.after_unify} へ")
    # なるべく新しいグループは作成しないようにする。
    # 操作先のグループが見つからない場合は、操作元グループを並び順で検索し、最初に見つけたものへ統合する。
    source_groups = self.class.group_class.in(name: changeset.sources.map { |source| source["name"] })
    source_groups = source_groups.reorder(order: :asc, name: :asc)
    source_groups = source_groups.to_a
    source_attributes_array = source_groups.map { |group| copy_attributes_deeply(group) }

    destination = changeset.destinations.first
    destination_group = find_or_create_group(destination, alternative_names: source_groups.map(&:name))
    unless save_or_collect_errors(destination_group)
      inc_counter(:unify, :failed)
      return
    end

    put_log("created/updated group: #{destination_group.name}(#{destination_group.id})")
    inc_counter(:unify, :success)

    add_group_to_site(destination_group)

    if destination[:contact_groups].present?
      destination_main_contact = destination[:contact_groups].find { |contact| contact[:main_state] == 'main' }
    end

    source_attributes_array.each do |source_attributes|
      substitutor.collect(source_attributes, destination_group.attributes, [destination_group.id])
      source_id = source_attributes[:_id]
      if source_id != destination_group.id
        move_users_group(source_id, destination_group.id)
        delete_group_ids << source_id
      end
      if destination_main_contact && destination_main_contact[:unifies_to_main] == 'enabled'
        unifies_contact_to_main(destination_group, source_id)
      end
    end
  end

  def execute_division(changeset)
    put_log("division #{changeset.before_division} to #{changeset.after_division}")
    task.log("  #{changeset.before_division} から #{changeset.after_division} へ")
    source = changeset.sources.first
    source_group = self.class.group_class.where(id: source["id"]).first
    if source_group.blank?
      put_warn("group not found: #{source["name"]}")
      return
    end
    source_attributes = copy_attributes_deeply(source_group)

    destination_groups = []
    unifies_to_main_groups = []
    changeset.destinations.map.with_index do |destination, index|
      # なるべく新しいグループは作成しないようにする。
      # 1 番目の分割先のグループが見つからない場合は、分割元グループへ分割結果をセットする。
      alternative_names = index == 0 ? [ source_group.name ] : nil
      group = find_or_create_group(destination, alternative_names: alternative_names)
      destination_groups << group

      if destination[:contact_groups].present?
        destination_main_contact = destination[:contact_groups].find { |contact| contact[:main_state] == 'main' }
      end
      if destination_main_contact && destination_main_contact[:unifies_to_main] == 'enabled'
        unifies_to_main_groups << group
      end
    end

    success = destination_groups.reduce(true) do |a, e|
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
    # pages' contacts
    divide_page_contacts(source_attributes, destination_groups)
    unifies_to_main_groups.each do |group|
      unifies_contact_to_main(group, group.id)
    end
    # group of page/node/layout/part has all division groups.
    substitutor.collect(source_attributes, destination_attributes, destination_group_ids)
    delete_group_ids << source_group.id unless destination_group_ids.include?(source_group.id)
  end

  def execute_delete(changeset)
    source_groups = changeset.sources.map do |source|
      self.class.group_class.where(id: source["id"]).first
    end
    source_groups.compact.each do |source_group|
      empty_attributes = {}
      source_group.attributes.select { |_, v| v.is_a?(Integer) }.each { |k, v| empty_attributes[k] = v }
      validation_substitutor.collect(source_group.attributes, empty_attributes)
      delete_group_ids << source_group.id
      inc_counter(:delete, :success)
    end
  end

  def execute_before(changesets)
    execute_before_gws_notice(changesets)
  end

  def execute_after(changesets)
    execute_after_gws_notice(changesets)
  end

  def divide_page_contacts(source_attributes, destination_groups)
    source_contact_groups_attributes = source_attributes["contact_groups"]
    return if source_contact_groups_attributes.blank?

    destination_group_contact_pairs = destination_groups.map do |group|
      group.contact_groups.to_a.map { |contact| [ group, contact ] }
    end
    destination_group_contact_pairs.flatten!(1)

    source_contact_groups_attributes.each do |contact_attributes|
      triple = destination_group_contact_pairs.find do |_group, contact|
        contact.id.to_s == contact_attributes["_id"].to_s || contact.name == contact_attributes["name"]
      end

      criteria = Cms::Page.all.where(contact_group_id: source_attributes['_id'], contact_group_relation: "related")
      criteria = criteria.where(contact_group_contact_id: contact_attributes['_id'].to_s)
      all_ids = criteria.pluck(:id)
      if triple.blank?
        # 連絡先のリンク切れ
        all_ids.each_slice(20) do |ids|
          criteria.in(id: ids).to_a.each do |page|
            page.contact_group_contact = nil

            if save_or_collect_errors(page)
              put_log("unifies contacts to main: #{page.name}(#{page.id})")
            else
              Rails.logger.warn("failed to unify contacts to main: #{page.errors.full_messages.join("\n")}")
            end
          end
        end
      else
        all_ids.each_slice(20) do |ids|
          criteria.in(id: ids).to_a.each do |page|
            page.contact_group = triple[0]
            page.contact_group_contact = triple[1]
            page.contact_charge = triple[1].contact_group_name
            page.contact_tel = triple[1].contact_tel
            page.contact_fax = triple[1].contact_fax
            page.contact_email = triple[1].contact_email
            page.contact_link_url = triple[1].contact_link_url
            page.contact_link_name = triple[1].contact_link_name

            if save_or_collect_errors(page)
              put_log("divided contact: #{page.name}(#{page.id})")
            else
              Rails.logger.warn("failed to unify contacts to main: #{page.errors.full_messages.join("\n")}")
            end
          end
        end
      end
    end
  end

  def unifies_contact_to_main(destination_group, source_id)
    destination_main_contact = destination_group.contact_groups.where(main_state: "main").first
    return if destination_main_contact.blank?
    return if source_id.blank?

    criteria = Cms::Page.all.where(contact_group_id: source_id, contact_group_relation: "related")
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |page|
        page.contact_group = destination_group
        page.contact_group_contact = destination_main_contact
        page.contact_charge = destination_main_contact.contact_group_name
        page.contact_tel = destination_main_contact.contact_tel
        page.contact_fax = destination_main_contact.contact_fax
        page.contact_email = destination_main_contact.contact_email
        page.contact_link_url = destination_main_contact.contact_link_url
        page.contact_link_name = destination_main_contact.contact_link_name

        if save_or_collect_errors(page)
          put_log("unifies contacts to main: #{page.name}(#{page.id})")
        else
          Rails.logger.warn("failed to unify contacts to main: #{page.errors.full_messages.join("\n")}")
        end
      end
    end
  end
end
