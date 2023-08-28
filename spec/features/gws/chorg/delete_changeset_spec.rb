require 'spec_helper'

describe "gws_chorg", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:revision) { create(:gws_revision, site_id: site.id) }
  let!(:group0) { create(:gws_group, name: "#{site.name}/#{unique_id}") }

  before { login_gws_user }

  context "add changeset 'delete'" do
    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      wait_for_js_ready
      click_on I18n.t("chorg.menus.revisions.delete")

      within "form#item-form" do
        wait_cbox_open { click_on I18n.t("chorg.views.delete_changesets.select_group") }
      end
      wait_for_cbox do
        wait_cbox_close { click_on group0.trailing_name }
      end
      within "form#item-form" do
        expect(page).to have_css(".ajax-selected [data-id='#{group0.id}']", text: group0.trailing_name)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      revision.reload
      expect(revision.changesets.count).to eq 1
      revision.changesets.first.tap do |changeset|
        expect(changeset.type).to eq "delete"
        expect(changeset.sources.length).to eq 1
        expect(changeset.sources).to include({ "id" => group0.id.to_s, "name" => group0.name })
        expect(changeset.destinations).to be_blank
      end
    end
  end

  context "edit changeset 'delete'" do
    let!(:changeset0) { create(:gws_delete_changeset, revision_id: revision.id, source: group0) }
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      wait_for_js_ready
      click_on changeset0.delete_description
      wait_for_js_ready
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        wait_cbox_open { click_on I18n.t("chorg.views.delete_changesets.select_group") }
      end
      wait_for_cbox do
        wait_cbox_close { click_on group1.trailing_name }
      end
      within "form#item-form" do
        expect(page).to have_css(".ajax-selected [data-id='#{group1.id}']", text: group1.trailing_name)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      revision.reload
      expect(revision.changesets.count).to eq 1

      changeset0.reload
      expect(changeset0.type).to eq "delete"
      expect(changeset0.sources.length).to eq 1
      expect(changeset0.sources).to include({ "id" => group1.id.to_s, "name" => group1.name })
      expect(changeset0.destinations).to be_blank
    end
  end

  context "remove changeset 'delete'" do
    let!(:changeset0) { create(:gws_delete_changeset, revision_id: revision.id, source: group0) }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      wait_for_js_ready
      click_on changeset0.delete_description
      wait_for_js_ready
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end

      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      revision.reload
      expect(revision.changesets.count).to eq 0
      expect { Gws::Chorg::Changeset.find(changeset0.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
