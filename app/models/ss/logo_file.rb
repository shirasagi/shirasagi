class SS::LogoFile
  include SS::Model::File

  default_scope ->{ where(model: "ss/logo_file") }

  def previewable?(site: nil, user: nil, member: nil)
    return false if owner_item.blank?
    return false if user.blank?

    if owner_item.is_a?(SS::Model::Site)
      names_to_match = owner_item.groups.active.pluck(:name).map { |name| /^#{::Regexp.escape(name)}(\/|$)/ }
      return user.groups.active.in(name: names_to_match).present?
    end
    if owner_item.is_a?(SS::Model::Group)
      return user.root_groups.any? { |group| group.id == owner_item_id }
    end

    false
  end
end
