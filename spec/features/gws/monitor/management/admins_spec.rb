require 'spec_helper'

describe "gws_monitor_management_admins", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let(:cur_group) { user.gws_default_group }
  let(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}", order: 10) }
  let(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}", order: 20) }

  let(:group_ss_file) { create_once(:ss_file, user: user, filename: "file1.png", name: "file1.png") }
  let(:own_ss_file) { create_once(:ss_file, user: user, filename: "file2.png", name: "file2.png") }

  let(:topic1) do
    create(
      :gws_monitor_topic, user: user, attend_group_ids: [g1.id, g2.id],
      state: 'public', article_state: 'open', spec_config: 'my_group',
      answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" },
      file_ids: [own_ss_file.id]
    )
  end
  let(:post1) do
    create(
      :gws_monitor_post, user: user, user_group_id: g1.id, user_group_name: g1.name, parent_id: topic1.id,
      file_ids: [group_ss_file.id]
    )
  end
  let(:download_filenames) do
    [
      "#{g1.order || 0}_#{g1.trailing_name}_#{group_ss_file.name}",
      "own_#{cur_group.order || 0}_#{cur_group.trailing_name}_#{own_ss_file.name}"
    ]
  end

  let(:topic2) do
    create(
      :gws_monitor_topic, user: user, attend_group_ids: [g1.id, g2.id], state: 'public',
      article_state: 'open', spec_config: 'my_group',
      answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      topic1
      visit gws_monitor_management_admins_path(site)
      expect(page).to have_content(topic1.name)
      expect(page).to have_content("#{I18n.t('gws/monitor.topic.answer_state')}(1/2)")
    end

    it "#edit" do
      visit edit_gws_monitor_management_admin_path(site, topic1)
      expect(page).to have_content(I18n.t("ss.basic_info"))
    end

    it "#show" do
      visit gws_monitor_management_admin_path(site, topic1)
      expect(page).to have_content(topic1.name)
    end

    it "#file_download" do
      post1

      visit gws_monitor_management_admin_path(site, topic1)
      expect(page).to have_content(topic1.name)

      click_link I18n.t("gws/monitor.links.file_download")

      Tempfile.open do |file|
        file.binmode
        file.write page.source

        entry_names = []
        Zip::File.open(file.path) do |entries|
          entries.each do |entry|
            entry_names << NKF.nkf("-w", entry.name)
          end
        end
        expect(entry_names).to match_array(download_filenames)
      end
    end

    it "#file_download when file not stored " do
      topic2

      visit gws_monitor_management_admin_path(site, topic2)
      expect(page).to have_content(topic2.name)
      expect(page).not_to have_link(I18n.t("gws/monitor.links.file_download"))
    end
  end
end
