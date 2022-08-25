require 'spec_helper'

describe "gws_chorg", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:revision) { create(:gws_revision, site_id: site.id) }
  let!(:group0) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
  let!(:group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }

  before { login_gws_user }

  context "add changeset 'unify'" do
    let!(:name) { unique_id }

    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.unify")

      within "form#item-form" do
        fill_in "item[destinations[][name]]", with: name
        click_on I18n.t("chorg.views.unify_changesets.select_group")
      end
      within "#ajax-box" do
        # click_on group0.trailing_name
        first("[data-id='#{group0.id}'] input[type='checkbox']").click
        # click_on group1.trailing_name
        first("[data-id='#{group1.id}'] input[type='checkbox']").click

        click_on I18n.t("ss.links.select")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t('ss.notice.saved'))

      revision.reload
      expect(revision.changesets.count).to eq 1
      revision.changesets.first.tap do |changeset|
        expect(changeset.type).to eq "unify"
        expect(changeset.sources.length).to eq 2
        expect(changeset.sources).to include({ "id" => group0.id.to_s, "name" => group0.name })
        expect(changeset.sources).to include({ "id" => group1.id.to_s, "name" => group1.name })
        expect(changeset.destinations.length).to eq 1
        expect(changeset.destinations).to include({ "name" => name, "order" => "", "ldap_dn" => "" })
      end
    end
  end

  context "edit changeset 'unify'" do
    let!(:changeset0) { create(:gws_unify_changeset, revision_id: revision.id, sources: [group0, group1]) }
    let!(:name) { unique_id }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on changeset0.after_unify
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[destinations[][name]]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t('ss.notice.saved'))

      revision.reload
      expect(revision.changesets.count).to eq 1

      changeset0.reload
      expect(changeset0.type).to eq "unify"
      expect(changeset0.sources.length).to eq 2
      expect(changeset0.sources).to include({ "id" => group0.id.to_s, "name" => group0.name })
      expect(changeset0.sources).to include({ "id" => group1.id.to_s, "name" => group1.name })
      expect(changeset0.destinations.length).to eq 1
      expect(changeset0.destinations).to include({ "name" => name, "order" => "", "ldap_dn" => "" })
    end
  end

  context "remove changeset 'unify'" do
    let!(:changeset0) { create(:gws_unify_changeset, revision_id: revision.id, sources: [group0, group1]) }

    it do
      revision.reload
      expect(revision.changesets.count).to eq 1

      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on changeset0.after_unify
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end

      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t('ss.notice.deleted'))

      revision.reload
      expect(revision.changesets.count).to eq 0
      expect { Gws::Chorg::Changeset.find(changeset0.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
