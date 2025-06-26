require 'spec_helper'

describe Gws::Tabular::Gws::FormsController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: admin }
  let!(:form1) { create :gws_tabular_form, cur_site: site, cur_user: admin, cur_space: space }
  let!(:form2) { create :gws_tabular_form, cur_site: site, cur_user: admin, cur_space: space }

  context "search by i18n_name" do
    it do
      login_user admin, to: gws_tabular_gws_spaces_path(site: site)
      click_on space.i18n_name
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/form")
      end
      expect(page).to have_css(".list-item[data-id]", count: 2)
      expect(page).to have_css(".list-item[data-id='#{form1.id}']", text: form1.i18n_name)
      expect(page).to have_css(".list-item[data-id='#{form2.id}']", text: form2.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: form1.i18n_name
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{form1.id}']", text: form1.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: form2.i18n_name
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{form2.id}']", text: form2.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: "name-#{unique_id}"
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 0)
    end
  end

  # 管理画面ではメモで検索可能
  context "search by memo" do
    let(:form1_memo) { form1.memo.split(/\R+/) }
    let(:form2_memo) { form2.memo.split(/\R+/) }

    it do
      login_user admin, to: gws_tabular_gws_spaces_path(site: site)
      click_on space.i18n_name
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/form")
      end
      expect(page).to have_css(".list-item[data-id]", count: 2)
      expect(page).to have_css(".list-item[data-id='#{form1.id}']", text: form1.i18n_name)
      expect(page).to have_css(".list-item[data-id='#{form2.id}']", text: form2.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: form1_memo.sample
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{form1.id}']", text: form1.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: form2_memo.sample
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{form2.id}']", text: form2.i18n_name)

      within "form.index-search" do
        fill_in "s[keyword]", with: "memo-#{unique_id}"
        click_on I18n.t("ss.buttons.search")
      end

      expect(page).to have_css(".list-item[data-id]", count: 0)
    end
  end
end
