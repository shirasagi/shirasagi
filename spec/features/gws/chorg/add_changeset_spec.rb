require 'spec_helper'

describe "gws_chorg", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:revision) { create(:gws_revision, site_id: site.id) }

  before { login_gws_user }

  context "add changeset 'add'" do
    let!(:name) { unique_id }

    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.add")

      within "form#item-form" do
        fill_in "item[destinations[][name]]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t('ss.notice.saved'))

      revision.reload
      expect(revision.changesets.count).to eq 1
      revision.changesets.first.tap do |changeset|
        expect(changeset.type).to eq "add"
        expect(changeset.sources).to be_blank
        expect(changeset.destinations.length).to eq 1
        expect(changeset.destinations).to include({ "name" => name, "order" => "", "ldap_dn" => "" })
      end
    end
  end

  context "edit changeset 'add'" do
    let!(:changeset0) { create(:gws_add_changeset, revision_id: revision.id) }
    let!(:name) { unique_id }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on changeset0.add_description
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[destinations[][name]]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t('ss.notice.saved'))

      revision.reload
      expect(revision.changesets.count).to eq 1

      changeset0.reload
      expect(changeset0.destinations.length).to eq 1
      expect(changeset0.destinations).to include({ "name" => name, "order" => "", "ldap_dn" => "" })
    end
  end

  context "remove changeset 'add'" do
    let!(:changeset0) { create(:gws_add_changeset, revision_id: revision.id) }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on changeset0.add_description
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end

      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t('ss.notice.deleted'))

      revision.reload
      expect(revision.changesets.count).to eq 0
      expect { Gws::Chorg::Changeset.find(changeset0.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
