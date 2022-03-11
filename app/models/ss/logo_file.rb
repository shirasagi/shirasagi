class SS::LogoFile
  include SS::Model::File
  # include SS::Relation::Thumb

  default_scope ->{ where(model: "ss/logo_file") }

  def previewable?(site: nil, user: nil, member: nil)
    return false if owner_item.blank?

    if owner_item.is_a?(SS::Model::Site)
      if user
        names_to_match = owner_item.groups.active.pluck(:name).map { |name| /^#{::Regexp.escape(name)}(\/|$)/ }
        return true if user.groups.active.in(name: names_to_match).present?
      end

      request = Rails.application.current_request
      if request
        request_host = request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"] || request.host_with_port
        return true if owner_item.domains.include?(request_host)
        return true if owner_item.mypage_domain == request_host
      end

      return false
    end

    if owner_item.is_a?(SS::Model::Group)
      return true if user && user.root_groups.any? { |group| group.id == owner_item_id }

      request = Rails.application.current_request
      if request
        request_host = request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"] || request.host_with_port
        return true if owner_item.domains.include?(request_host)
        return true if owner_item.canonical_domain == request_host
      end

      return false
    end

    # unknown owner_item class
    false
  end
end
