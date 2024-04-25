require 'spec_helper'

describe "gws_chorg", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:revision) { create(:gws_revision, site_id: site.id) }
  let!(:group0) { create(:gws_group, name: "#{site.name}/#{unique_id}") }

  before { login_gws_user }

  context "add changeset 'division'" do
    let(:name0) { unique_id }
    let(:name1) { unique_id }

    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.division")

      within "form#item-form" do
        click_on I18n.t("chorg.views.division_changesets.select_group")
      end
      within "#ajax-box" do
        click_on group0.trailing_name
      end
      within "form#item-form" do
        fill_in "item_destinations_0_name", with: name0
        fill_in "item_destinations_1_name", with: name1
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      revision.reload
      expect(revision.changesets.count).to eq 1
      revision.changesets.first.tap do |changeset|
        expect(changeset.type).to eq "division"
        expect(changeset.sources.length).to eq 1
        expect(changeset.sources).to include({ "id" => group0.id.to_s, "name" => group0.name })
        expect(changeset.destinations.length).to eq 2
        expect(changeset.destinations).to include({ "name" => name0, "order" => "", "ldap_dn" => "" })
        expect(changeset.destinations).to include({ "name" => name1, "order" => "", "ldap_dn" => "" })
      end
    end
  end

  context "edit changeset 'division'" do
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:changeset0) do
      create(:gws_division_changeset, revision_id: revision.id, source: group0, destinations: [group1, group2])
    end
    let!(:name) { unique_id }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on changeset0.after_division
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item_destinations_0_name", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      revision.reload
      expect(revision.changesets.count).to eq 1

      changeset0.reload
      expect(changeset0.type).to eq "division"
      expect(changeset0.sources.length).to eq 1
      expect(changeset0.sources).to include({ "id" => group0.id.to_s, "name" => group0.name })
      expect(changeset0.destinations.length).to eq 2
      expect(changeset0.destinations).to include({ "name" => name, "order" => "", "ldap_dn" => "" })
      expect(changeset0.destinations).to include({ "name" => group2.name, "order" => "", "ldap_dn" => "" })
    end
  end

  context "remove changeset 'division'" do
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:changeset0) do
      create(:gws_division_changeset, revision_id: revision.id, source: group0, destinations: [group1, group2])
    end

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on changeset0.after_division
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
