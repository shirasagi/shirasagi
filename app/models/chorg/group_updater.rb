class Chorg::GroupUpdater
  include ActiveModel::Model

  attr_accessor :item, :replacement_hash

  def call
    replacement_hash.each do |k, v|
      if v.respond_to?(:update_entity)
        v.update_entity(item_attributes)
      elsif k == "contact_groups"
        update_item_contact_groups(v)
      elsif k.start_with?("contact_")
        update_main_contact_attribute(k, v)
      else
        update_item_attribute(k, v)
      end
    end

    ensure_contacts_have_name
    item.attributes = item_attributes
    item
  end

  private

  def item_attributes
    @item_attributes ||= begin
      attributes = Hash.new { |hash, key| hash[key] = item[key] }
      # attributes["contact_groups"] = item.contact_groups.map(&:attributes).map(&:to_h)
      attributes["contact_groups"] = []
      attributes
    end
  end

  def update_item_attribute(name, value)
    item_attributes[name] = value
  end

  def main_contact_attributes
    @main_contact_attributes ||= begin
      main_contact = item_attributes["contact_groups"].find { |contact_group| contact_group["main_state"] == "main" }
      main_contact ||= item.contact_groups.where(main_state: "main").first.try(:attributes).try(:to_h)
      unless main_contact
        main_contact = { "main_state" => "main", "name" => "main" }.with_indifferent_access
        item_attributes["contact_groups"] << main_contact
      end
      main_contact
    end
  end

  def update_main_contact_attribute(name, value)
    main_contact_attributes[name] = value
  end

  def find_contact_by_id(id)
    id = id.to_s if id.present?
    contact = item_attributes["contact_groups"].find { |contact_group| contact_group["_id"].to_s == id }
    return contact if contact

    contact = item.contact_groups.where(id: id).first
    if contact
      contact = contact.attributes.to_h
      item_attributes["contact_groups"] << contact
    end
    contact
  end

  def find_contact_by_name(name)
    contact = item_attributes["contact_groups"].find { |contact_group| contact_group["name"] == name }
    return contact if contact

    contact = item.contact_groups.where(name: name).first
    if contact
      contact = contact.attributes.to_h
      item_attributes["contact_groups"] << contact
    end
    contact
  end

  def update_item_contact_groups(array)
    if array.blank?
      item_attributes["contact_groups"] = []
      return
    end

    array.each do |hash|
      if hash["_id"].present?
        contact = find_contact_by_id(hash["_id"])
      end
      if contact.blank? && hash["name"].present?
        contact = find_contact_by_name(hash["name"])
      end

      if contact.blank?
        hash = hash.dup
        hash.delete("unifies_to_main")
        item_attributes["contact_groups"] << hash
        next
      end

      contact["name"] = hash["name"] if hash.key?("name")
      contact["contact_group_name"] = hash["contact_group_name"] if hash.key?("contact_group_name")
      contact["contact_tel"] = hash["contact_tel"] if hash.key?("contact_tel")
      contact["contact_fax"] = hash["contact_fax"] if hash.key?("contact_fax")
      contact["contact_email"] = hash["contact_email"] if hash.key?("contact_email")
      contact["contact_link_url"] = hash["contact_link_url"] if hash.key?("contact_link_url")
      contact["contact_link_name"] = hash["contact_link_name"] if hash.key?("contact_link_name")
      contact["main_state"] = hash["main_state"] if hash.key?("main_state")
    end
  end

  def ensure_contacts_have_name
    return if item_attributes["contact_groups"].blank?

    item_attributes["contact_groups"].each do |contact|
      next if contact.blank?
      next if contact["name"].present?

      contact["name"] = contact["main_state"] == "main" ? unique_contact_main_name : unique_contact_name
    end
  end

  def unique_contact_main_name
    return "main" unless item_attributes["contact_groups"].any? { |contact| contact["name"] == "main" }
    unique_contact_name
  end

  def unique_contact_name
    trailing_name = item_attributes["name"].split("/").last

    loop do
      seq = next_sequence
      contact_name = "#{trailing_name}-#{seq}"
      next if item_attributes["contact_groups"].any? { |contact| contact["name"] == contact_name }

      return contact_name
    end
  end

  def next_sequence
    @sequence ||= 0
    @sequence += 1
  end
end
