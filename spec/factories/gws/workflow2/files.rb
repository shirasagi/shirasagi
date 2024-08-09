FactoryBot.define do
  factory :gws_workflow2_file, class: Gws::Workflow2::File do
    transient do
      name { nil }
    end

    cur_site { gws_site }
    cur_user { gws_user }

    i18n_name_translations do
      if name
        { I18n.default_locale => name }.with_indifferent_access
      else
        i18n_translations(prefix: "name")
      end
    end
    text { "text-#{unique_id}" }
    file_ids { [ create(:ss_temp_file).id ] }

    destination_treat_state do
      if destination_group_ids.blank? && destination_user_ids.blank?
        "no_need_to_treat"
      else
        "untreated"
      end
    end
  end
end
