FactoryBot.define do
  factory :add_changeset, class: Chorg::Changeset do
    type { Chorg::Changeset::TYPE_ADD }
    destinations do
      [
        {
          name: "組織変更/新設グループ_#{unique_id}",
          order: rand(1..10).to_s,
          ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
          contact_groups: [
            {
              main_state: "main",
              name: "main",
              contact_group_name: "name-#{unique_id}",
              contact_tel: unique_tel,
              contact_fax: unique_tel,
              contact_email: unique_email,
              contact_link_url: "/#{unique_id}/",
              contact_link_name: "link-#{unique_id}",
            }.with_indifferent_access
          ]
        }.with_indifferent_access
      ]
    end
  end

  factory :move_changeset, class: Chorg::Changeset do
    transient do
      source { nil }
    end

    type { Chorg::Changeset::TYPE_MOVE }
    sources { [ { id: source.id, name: source.name }.stringify_keys ] }
    destinations do
      [
        {
          name: "組織変更/移動グループ_#{unique_id}",
          order: rand(1..10).to_s,
          ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
          contact_groups: [
            {
              main_state: "main",
              name: "main",
              contact_group_name: "name-#{unique_id}",
              contact_tel: unique_tel,
              contact_fax: unique_tel,
              contact_email: unique_email,
              contact_link_url: "/#{unique_id}/",
              contact_link_name: "link-#{unique_id}",
            }.with_indifferent_access
          ]
        }.with_indifferent_access
      ]
    end
  end

  factory :move_changeset_only_name, class: Chorg::Changeset do
    transient do
      source { nil }
    end

    type { Chorg::Changeset::TYPE_MOVE }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }
    destinations do
      [
        {
          name: "組織変更/新設グループ_#{unique_id}",
          order: source.order.to_s,
          ldap_dn: source.ldap_dn,
          contact_groups: source.contact_groups.map do |contact|
            {
              _id: contact.id.to_s,
              main_state: contact.main_state,
              name: contact.name,
              contact_group_name: contact.contact_group_name,
              contact_tel: contact.contact_tel,
              contact_fax: contact.contact_fax,
              contact_email: contact.contact_email,
              contact_link_url: contact.contact_link_url,
              contact_link_name: contact.contact_link_name,
            }.with_indifferent_access
          end
        }.with_indifferent_access
      ]
    end
  end

  factory :unify_changeset, class: Chorg::Changeset do
    transient do
      sources { nil }
      destination { nil }
    end

    type { Chorg::Changeset::TYPE_UNIFY }
    destinations do
      contact_groups = sources.map do |group|
        group.contact_groups.map do |contact|
          {
            _id: contact.id.to_s,
            main_state: contact.main_state.presence,
            name: "name-#{unique_id}",
            contact_group_name: "contact-#{unique_id}",
            contact_tel: unique_tel,
            contact_fax: unique_tel,
            contact_email: unique_email,
            contact_link_url: "/#{unique_id}/",
            contact_link_name: "link-#{unique_id}",
          }.with_indifferent_access
        end
      end
      contact_groups.flatten!
      if contact_groups.present?
        main_contact = contact_groups.find { |contact| contact[:main_state] == "main" }
        if main_contact.blank?
          contact_groups[0][:main_state] = "main"
        else
          contact_groups.each { |contact| contact[:main_state] = main_contact[:_id] == contact[:_id] ? "main" : nil }
        end
      end

      [
        {
          name: "組織変更/新設グループ_#{unique_id}",
          order: rand(1..10).to_s,
          ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
          contact_groups: contact_groups
        }.with_indifferent_access
      ]
    end

    after(:build) do |entity, evaluator|
      entity.sources = evaluator.sources.map do |group|
        { id: group.id, name: group.name }.with_indifferent_access
      end
      if evaluator.destination.present? && entity.destinations.present? && entity.destinations[0].present?
        entity.destinations[0][:name] = evaluator.destination.name
        entity.destinations[0][:order] = evaluator.destination.order
        entity.destinations[0][:ldap_dn] = evaluator.destination.ldap_dn
      end
    end
  end

  factory :division_changeset, class: Chorg::Changeset do
    transient do
      source { nil }
      destination { nil }
    end

    type { Chorg::Changeset::TYPE_DIVISION }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }

    after(:build) do |entity, evaluator|
      if evaluator.destination
        entity.destinations = Array(evaluator.destination).map do |group|
          destination = {
            name: group.name, order: group.order, ldap_dn: group.ldap_dn
          }.with_indifferent_access

          destination[:contact_groups] = group.contact_groups.map do |contact_group|
            {
              _id: contact_group.id.to_s,
              main_state: contact_group.main_state,
              name: contact_group.name,
              contact_group_name: contact_group.contact_group_name,
              contact_email: contact_group.contact_email,
              contact_tel: contact_group.contact_tel,
              contact_fax: contact_group.contact_fax,
              contact_link_url: contact_group.contact_link_url,
              contact_link_name: contact_group.contact_link_name,
            }.with_indifferent_access
          end

          destination
        end
      end
    end
  end

  factory :delete_changeset, class: Chorg::Changeset do
    transient do
      source { nil }
    end

    type { Chorg::Changeset::TYPE_DELETE }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }
  end
end
