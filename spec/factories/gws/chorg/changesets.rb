FactoryBot.define do
  factory :gws_add_changeset, class: Gws::Chorg::Changeset do
    type { Chorg::Model::Changeset::TYPE_ADD }
    destinations { [ { name: "組織変更/新設グループ_#{unique_id}" }.with_indifferent_access ] }
  end

  factory :gws_move_changeset, class: Gws::Chorg::Changeset do
    transient do
      source { nil }
    end

    type { Chorg::Model::Changeset::TYPE_MOVE }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }
    destinations do
      [ { name: "組織変更/新設グループ_#{unique_id}",
          order: "",
          ldap_dn: "" }.with_indifferent_access ]
    end
  end

  factory :gws_move_changeset_only_name, class: Gws::Chorg::Changeset do
    transient do
      source { nil }
    end

    type { Chorg::Model::Changeset::TYPE_MOVE }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }
    destinations do
      [ { name: "組織変更/新設グループ_#{unique_id}",
          order: "",
          ldap_dn: "" }.with_indifferent_access ]
    end
  end

  factory :gws_unify_changeset, class: Gws::Chorg::Changeset do
    transient do
      sources { nil }
      destination { nil }
    end

    type { Chorg::Model::Changeset::TYPE_UNIFY }
    destinations do
      [ { name: "組織変更/新設グループ_#{unique_id}",
          order: "",
          ldap_dn: "" }.with_indifferent_access ]
    end

    after(:build) do |entity, evaluator|
      entity.sources = evaluator.sources.map do |group|
        { id: group.id, name: group.name }.with_indifferent_access
      end.to_a
      if evaluator.destination.present?
        entity.destinations = [ { name: evaluator.destination.name }.with_indifferent_access ]
      end
    end
  end

  factory :gws_division_changeset, class: Gws::Chorg::Changeset do
    transient do
      source { nil }
      destinations { nil }
    end

    type { Chorg::Model::Changeset::TYPE_DIVISION }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }

    after(:build) do |entity, evaluator|
      entity.destinations = evaluator.destinations.map do |group|
        { name: group.name,
          order: group.order,
          ldap_dn: group.ldap_dn }.with_indifferent_access
      end.to_a
    end
  end

  factory :gws_delete_changeset, class: Gws::Chorg::Changeset do
    transient do
      source { nil }
    end

    type { Chorg::Model::Changeset::TYPE_DELETE }
    sources { [ { id: source.id, name: source.name }.with_indifferent_access ] }
  end
end
