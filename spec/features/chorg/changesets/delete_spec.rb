require 'spec_helper'

describe "chorg_changesets", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:revision) { create(:revision, cur_site: site) }
  let!(:group1) do
    create(
      :cms_group, name: "#{cms_group.name}/#{unique_id}",
      contact_groups: [
        {
          main_state: "main", name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        },
        {
          main_state: nil, name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        }
      ]
    )
  end
  let!(:group2) do
    create(
      :cms_group, name: "#{cms_group.name}/#{unique_id}",
      contact_groups: [
        {
          main_state: "main", name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        },
        {
          main_state: nil, name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        }
      ]
    )
  end

  before do
    login_cms_user
  end

  context "basic crud: delete" do
    it do
      #
      # Create
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-delete" do
        click_on I18n.t("chorg.menus.revisions.delete")
      end
      within "form#item-form" do
        within "#chorg-before-basic" do
          wait_cbox_open { click_on I18n.t("chorg.views.delete_changesets.select_group") }
        end
      end
      wait_for_cbox do
        wait_cbox_close { click_on group1.trailing_name }
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      revision.reload
      expect(revision.changesets).to have(1).items
      revision.changesets.first.tap do |changeset|
        expect(changeset.revision_id).to eq revision.id
        expect(changeset.type).to eq "delete"
        expect(changeset.sources).to have(1).items
        changeset.sources.first.tap do |source|
          expect(source["id"]).to eq group1.id.to_s
          expect(source["name"]).to eq group1.name
        end
        expect(changeset.destinations).to be_blank
      end

      #
      # Update
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-delete" do
        click_on group1.name
      end
      expect(page).to have_css(".chorg-before", text: group1.name)
      # expect(page).to have_content(group1.name)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        within "#chorg-before-basic" do
          wait_cbox_open { click_on I18n.t("chorg.views.delete_changesets.select_group") }
        end
      end
      wait_for_cbox do
        wait_cbox_close { click_on group2.trailing_name }
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      revision.reload
      expect(revision.changesets).to have(1).items
      revision.changesets.first.tap do |changeset|
        expect(changeset.revision_id).to eq revision.id
        expect(changeset.type).to eq "delete"
        expect(changeset.sources).to have(1).items
        changeset.sources.first.tap do |source|
          expect(source["id"]).to eq group2.id.to_s
          expect(source["name"]).to eq group2.name
        end
        expect(changeset.destinations).to be_blank
      end

      #
      # Delete
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-delete" do
        click_on group2.name
      end
      expect(page).to have_css(".chorg-before", text: group2.name)
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      revision.reload
      expect(revision.changesets).to be_blank
    end
  end
end
