require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:admin) { gws_user }
  let!(:folder) { create :gws_share_folder, cur_site: site, cur_user: admin, readable_setting_range: "public" }
  let!(:category) { create :gws_share_category, cur_site: site, cur_user: admin }
  let!(:item) do
    create(
      :gws_share_file, cur_site: site, cur_user: admin, folder: folder, category_ids: [ category.id ],
      readable_setting_range: "public")
  end

  describe "crud with editor" do
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:role1) { create :gws_role, :gws_role_share_editor, cur_site: site }
    let!(:user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role1.id ] }

    it do
      login_user user1, to: gws_share_files_path(site: site)
      expect(page).to have_css(".list-item[data-id='#{item.id}']", text: item.name)

      click_on item.name
      expect(page).to have_content(item.name)
    end
  end

  describe "download all with editor" do
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:role1) { create :gws_role, :gws_role_share_editor, cur_site: site }
    let!(:user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role1.id ] }

    it do
      login_user user1, to: gws_share_files_path(site: site)
      expect(page).to have_css(".list-item[data-id='#{item.id}']", text: item.name)

      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }

      wait_for_download("share_", extname: ".zip") do
        page.accept_confirm I18n.t("gws/share.links.confirm.download_all") do
          within ".list-head-action" do
            click_on I18n.t("ss.buttons.download")
          end
        end
      end

      entries = []
      Zip::File.open(downloaded_path) do |zip_file|
        zip_file.each do |entry|
          name = NKF.nkf("-w", entry.name)
          entries.append(name)
        end
      end
      expect(entries).to have(1).items
      expect(entries).to include(item.name)
    end
  end
end
