FactoryBot.define do
  factory :gws_notice_folder, class: Gws::Notice::Folder do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }

    notice_total_body_size_limit { SS.config.gws.notice['default_notice_total_body_size_limit'] }
    notice_individual_file_size_limit { SS.config.gws.notice['default_notice_individual_file_size_limit'] }
    notice_total_file_size_limit { SS.config.gws.notice['default_notice_total_file_size_limit'] }

    member_group_ids { ([ cur_site.id ] + cur_user.group_ids).compact.uniq }
  end
end
