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

  context "delete all" do
    it do
      expect(Gws::Tabular::View::Base.all.count).to eq 2

      login_user admin, to: gws_tabular_gws_spaces_path(site: site)
      click_on space.i18n_name
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/view/base")
      end
      expect(page).to have_css(".list-item[data-id]", count: 2)
      expect(page).to have_css(".list-item[data-id='#{view1.id}']", text: view1.i18n_name)
      expect(page).to have_css(".list-item[data-id='#{view2.id}']", text: view2.i18n_name)

      within ".list-head" do
        wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
        expect(page).to have_css(".badge", text: "2")
        page.accept_confirm(I18n.t("ss.confirm.delete")) do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Tabular::View::Base.all.count).to eq 0
    end
  end

  context "delete specified" do
    let(:delete_view) { [ view1, view2 ].sample }

    it do
      expect(Gws::Tabular::View::Base.all.count).to eq 2

      login_user admin, to: gws_tabular_gws_spaces_path(site: site)
      click_on space.i18n_name
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/view/base")
      end
      expect(page).to have_css(".list-item[data-id]", count: 2)
      expect(page).to have_css(".list-item[data-id='#{view1.id}']", text: view1.i18n_name)
      expect(page).to have_css(".list-item[data-id='#{view2.id}']", text: view2.i18n_name)

      within ".list-item[data-id='#{delete_view.id}']" do
        find('input[type="checkbox"]').set(true)
      end

      within ".list-head" do
        expect(page).to have_css(".badge", text: "1")
        page.accept_confirm(I18n.t("ss.confirm.delete")) do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Tabular::View::Base.all.count).to eq 1
      expect { delete_view.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
