require 'spec_helper'

describe Gws::Tabular::Gws::SpacesController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:space1) { create :gws_tabular_space, cur_site: site, cur_user: admin }
  let!(:space2) { create :gws_tabular_space, cur_site: site, cur_user: admin }

  context "search by i18n_name" do
    context "default" do
      it do
        login_user admin, to: gws_tabular_gws_spaces_path(site: site)
        expect(page).to have_css(".list-item[data-id]", count: 2)
        expect(page).to have_css(".list-item[data-id='#{space1.id}']", text: space1.i18n_name)
        expect(page).to have_css(".list-item[data-id='#{space2.id}']", text: space2.i18n_name)
      end
    end

    context "no items matched" do
      it do
        login_user admin, to: gws_tabular_gws_spaces_path(site: site, s: { keyword: "name-#{unique_id}" })
        expect(page).to have_css(".list-item[data-id]", count: 0)
      end
    end

    context "space1 name" do
      it do
        login_user admin, to: gws_tabular_gws_spaces_path(site: site, s: { keyword: "name-#{unique_id}" })
        within "form.index-search" do
          fill_in "s[keyword]", with: space1.i18n_name
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item[data-id]", count: 1)
        expect(page).to have_css(".list-item[data-id='#{space1.id}']", text: space1.i18n_name)
      end
    end

    context "space2 name" do
      it do
        login_user admin, to: gws_tabular_gws_spaces_path(site: site, s: { keyword: "name-#{unique_id}" })
        within "form.index-search" do
          fill_in "s[keyword]", with: space2.i18n_name
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item[data-id]", count: 1)
        expect(page).to have_css(".list-item[data-id='#{space2.id}']", text: space2.i18n_name)
      end
    end
  end

  # 管理画面ではメモで検索可能
  context "search by memo" do
    let(:space1_memo) { space1.memo.split(/\R+/) }
    let(:space2_memo) { space2.memo.split(/\R+/) }

    context "default" do
      it do
        login_user admin, to: gws_tabular_gws_spaces_path(site: site)
        expect(page).to have_css(".list-item[data-id]", count: 2)
        expect(page).to have_css(".list-item[data-id='#{space1.id}']", text: space1.i18n_name)
        expect(page).to have_css(".list-item[data-id='#{space2.id}']", text: space2.i18n_name)
      end
    end

    context "no items matched" do
      it do
        login_user admin, to: gws_tabular_gws_spaces_path(site: site, s: { keyword: "memo-#{unique_id}" })
        expect(page).to have_css(".list-item[data-id]", count: 0)
      end
    end

    context "space1 memo" do
      it do
        login_user admin, to: gws_tabular_gws_spaces_path(site: site, s: { keyword: "memo-#{unique_id}" })
        within "form.index-search" do
          fill_in "s[keyword]", with: space1_memo.sample
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item[data-id]", count: 1)
        expect(page).to have_css(".list-item[data-id='#{space1.id}']", text: space1.i18n_name)
      end
    end

    context "space2 memo" do
      it do
        login_user admin, to: gws_tabular_gws_spaces_path(site: site, s: { keyword: "memo-#{unique_id}" })
        within "form.index-search" do
          fill_in "s[keyword]", with: space2_memo.sample
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item[data-id]", count: 1)
        expect(page).to have_css(".list-item[data-id='#{space2.id}']", text: space2.i18n_name)
      end
    end
  end
end
