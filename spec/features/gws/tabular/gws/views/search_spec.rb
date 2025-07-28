require 'spec_helper'

describe Gws::Tabular::Gws::ViewsController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: admin }
  let!(:form) do
    create :gws_tabular_form, cur_site: site, cur_user: admin, cur_space: space, state: 'publishing', revision: 1
  end
  let!(:view1) do
    create :gws_tabular_view_list, cur_site: site, cur_user: admin, cur_space: space, cur_form: form
  end
  let!(:view2) do
    create :gws_tabular_view_liquid, cur_site: site, cur_user: admin, cur_space: space, cur_form: form
  end

  context "search by i18n_name" do
    it do
      login_user admin, to: gws_tabular_gws_spaces_path(site: site)
      click_on space.i18n_name
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/view/base")
      end
      expect(page).to have_css(".list-item[data-id]", count: 2)
      expect(page).to have_css(".list-item[data-id='#{view1.id}']", text: view1.i18n_name)
      expect(page).to have_css(".list-item[data-id='#{view2.id}']", text: view2.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: view1.i18n_name
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{view1.id}']", text: view1.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: view2.i18n_name
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{view2.id}']", text: view2.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: "name-#{unique_id}"
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 0)
    end
  end

  # 管理画面ではメモで検索可能
  context "search by memo" do
    let(:view1_memo) { view1.memo.split(/\R+/) }
    let(:view2_memo) { view2.memo.split(/\R+/) }

    it do
      login_user admin, to: gws_tabular_gws_spaces_path(site: site)
      click_on space.i18n_name
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/view/base")
      end
      expect(page).to have_css(".list-item[data-id]", count: 2)
      expect(page).to have_css(".list-item[data-id='#{view1.id}']", text: view1.i18n_name)
      expect(page).to have_css(".list-item[data-id='#{view2.id}']", text: view2.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: view1_memo.sample
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{view1.id}']", text: view1.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: view2_memo.sample
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{view2.id}']", text: view2.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: "memo-#{unique_id}"
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 0)
    end
  end
end
