require 'spec_helper'

describe "gws_chorg", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:revision) { create(:gws_revision, site_id: site.id) }
  let!(:group0) { create(:gws_group, name: "#{site.name}/#{unique_id}") }

  before { login_gws_user }

  context "add changeset 'move'" do
    let(:name) { unique_id }

    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      wait_for_js_ready
      click_on I18n.t("chorg.menus.revisions.move")

      within "form#item-form" do
        fill_in "item[destinations[][name]]", with: name
        wait_cbox_open { click_on I18n.t("chorg.views.move_changesets.select_group") }
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
        expect(changeset.type).to eq "move"
        expect(changeset.sources.length).to eq 1
        expect(changeset.sources).to include({ "id" => group0.id.to_s, "name" => group0.name })
        expect(changeset.destinations.length).to eq 1
        expect(changeset.destinations).to include({ "name" => name, "order" => "", "ldap_dn" => "" })
      end
    end
  end

  context "edit changeset 'move'" do
    let!(:changeset0) { create(:gws_move_changeset, revision_id: revision.id, source: group0) }
    let!(:name) { unique_id }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      wait_for_js_ready
      click_on changeset0.after_move
      wait_for_js_ready
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[destinations[][name]]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      revision.reload
      expect(revision.changesets.count).to eq 1

      changeset0.reload
      expect(changeset0.destinations.length).to eq 1
      expect(changeset0.destinations).to include({ "name" => name, "order" => "", "ldap_dn" => "" })
    end
  end

  context "remove changeset 'add'" do
    let!(:changeset0) { create(:gws_move_changeset, revision_id: revision.id, source: group0) }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      wait_for_js_ready
      click_on changeset0.after_move
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
