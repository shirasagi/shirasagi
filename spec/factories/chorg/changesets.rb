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

    after(:build) do |entity, evaluator|
      entity.sources = evaluator.sources.map do |group|
        { id: group.id, name: group.name }.with_indifferent_access
      end
      if evaluator.destination.present?
        name_set = Set.new
        includes_main = false

        destination = {
          name: evaluator.destination.name, order: evaluator.destination.order, ldap_dn: evaluator.destination.ldap_dn
        }.with_indifferent_access

        contact_groups = evaluator.destination.contact_groups.map do |contact_group|
          name = contact_group.name
          if name_set.include?(name)
            1.upto(10).each do |seq|
              name = "#{evaluator.destination.trailing_name}-#{seq}"
              break unless name_set.include?(name)
            end
          end
          name_set.add(name)

          main_state = contact_group.main_state
          if main_state == "main"
            if includes_main
              main_state = nil
            end
            includes_main = true
          end

          {
            _id: contact_group.id.to_s,
            main_state: main_state,
            name: name,
            contact_group_name: contact_group.contact_group_name,
            contact_email: contact_group.contact_email,
            contact_tel: contact_group.contact_tel,
            contact_fax: contact_group.contact_fax,
            contact_link_url: contact_group.contact_link_url,
            contact_link_name: contact_group.contact_link_name,
          }.with_indifferent_access
        end

        evaluator.sources.each do |source|
          contact_groups += source.contact_groups.map do |contact_group|
            name = contact_group.name
            if name_set.include?(name)
              1.upto(10).each do |seq|
                name = "#{evaluator.destination.trailing_name}-#{seq}"
                break unless name_set.include?(name)
              end
            end
            name_set.add(name)

            main_state = contact_group.main_state
            if main_state == "main"
              if includes_main
                main_state = nil
              end
              includes_main = true
            end

            {
              _id: contact_group.id.to_s,
              main_state: main_state,
              name: name,
              contact_group_name: contact_group.contact_group_name,
              contact_email: contact_group.contact_email,
              contact_tel: contact_group.contact_tel,
              contact_fax: contact_group.contact_fax,
              contact_link_url: contact_group.contact_link_url,
              contact_link_name: contact_group.contact_link_name,
            }.with_indifferent_access
          end
        end

        destination[:contact_groups] = contact_groups
        entity.destinations = [ destination ]
      end
    end
  end

  factory :division_changeset, class: Chorg::Changeset do
    transient do
      source { nil }
      destinations { nil }
    end

    type { Chorg::Changeset::TYPE_DIVISION }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }

    after(:build) do |entity, evaluator|
      entity.destinations = evaluator.destinations.map do |group|
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

  factory :delete_changeset, class: Chorg::Changeset do
    transient do
      source { nil }
    end

    type { Chorg::Changeset::TYPE_DELETE }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }
  end
end
