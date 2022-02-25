require 'spec_helper'

describe "gws_switch_group", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:default_group) { gws_user.groups.first }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  before do
    Gws::User.find(gws_user.id).tap do |user|
      # メンバー変数が汚染されるとテストで思わぬ結果をうむ場合がある。
      # そこで、データベースからユーザーをロードし、必要処理を実行後、インスタンスを破棄する。
      user.cur_site = site
      user.in_gws_main_group_id = default_group.id
      user.group_ids = user.group_ids + [ group1.id, group2.id, group3.id ]
      user.save!
    end
    gws_user.reload

    login_gws_user
  end

  it do
    Gws::User.find(gws_user.id).tap do |user|
      user.cur_site = site
      expect(user.gws_main_group_ids[site.id.to_s]).to eq default_group.id
      expect(user.gws_default_group_ids).to be_blank
    end
    visit gws_portal_path(site: site)

    within "nav.user" do
      # click_on user.name
      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(page).to have_css("h2", text: "#{user.gws_default_group.trailing_name} #{user.name}")
        find("span.name").click
      end

      within "#user-main-dropdown" do
        click_on I18n.t("gws.links.switch_group")
      end

      within "#gws-group-switch-menu" do
        expect(page).to have_css(".gws-group-switch-name", text: group1.section_name)
        expect(page).to have_css(".gws-group-switch-name", text: group2.section_name)
        expect(page).to have_css(".gws-group-switch-name", text: group3.section_name)

        click_on group2.section_name
      end
    end

    within "nav.user" do
      expect(page).to have_css("h2", text: "#{group2.trailing_name} #{gws_user.name}")
    end
    Gws::User.find(gws_user.id).tap do |user|
      user.cur_site = site
      expect(user.gws_main_group_ids).to include(site.id.to_s => default_group.id)
      expect(user.gws_default_group_ids).to include(site.id.to_s => group2.id)
    end
  end
end
