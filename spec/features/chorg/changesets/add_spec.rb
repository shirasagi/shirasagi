require 'spec_helper'

describe "chorg_changesets", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:revision) { create(:revision, cur_site: site) }

  before do
    login_cms_user
  end

  context "basic crud: add" do
    let(:new_name) { "name-#{unique_id}" }
    let(:new_name2) { "name-#{unique_id}" }
    let(:new_order) { rand(1..10) }
    let(:new_ldap_dn) { "dc=#{new_name},dc=city,dc=example,dc=jp" }
    let(:new_contact_name1) { unique_id }
    let(:new_contact_group_name1) { unique_id }
    let(:new_contact_tel1) { unique_tel }
    let(:new_contact_fax1) { unique_tel }
    let(:new_contact_email1) { unique_email }
    let(:new_contact_link_url1) { "/#{unique_id}/" }
    let(:new_contact_link_name1) { unique_id }
    let(:new_contact_name2) { unique_id }
    let(:new_contact_group_name2) { unique_id }
    let(:new_contact_tel2) { unique_tel }
    let(:new_contact_fax2) { unique_tel }
    let(:new_contact_email2) { unique_email }
    let(:new_contact_link_url2) { "/#{unique_id}/" }
    let(:new_contact_link_name2) { unique_id }

    it do
      #
      # Create
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-add" do
        click_on I18n.t("chorg.menus.revisions.add")
      end
      within "form#item-form" do
        within "#chorg-after-basic" do
          fill_in "item[destinations][][name]", with: new_name
          fill_in "item[destinations][][order]", with: new_order
        end
        within "#chorg-after-ldap" do
          fill_in "item[destinations][][ldap_dn]", with: new_ldap_dn
        end
        within "#chorg-after-contact" do
          within all("tr[data-id='new']")[0] do
            # click_on I18n.t("contact.options.main_state.main")
            first('[name="dummy[chorg-after-contact][][main_state]"]').click
            fill_in "item[destinations][][contact_groups][][name]", with: new_contact_name1
            fill_in "item[destinations][][contact_groups][][contact_group_name]", with: new_contact_group_name1
            fill_in "item[destinations][][contact_groups][][contact_tel]", with: new_contact_tel1
            fill_in "item[destinations][][contact_groups][][contact_fax]", with: new_contact_fax1
            fill_in "item[destinations][][contact_groups][][contact_email]", with: new_contact_email1
            fill_in "item[destinations][][contact_groups][][contact_link_url]", with: new_contact_link_url1
            fill_in "item[destinations][][contact_groups][][contact_link_name]", with: new_contact_link_name1
          end
          click_on I18n.t("ss.buttons.add")
          within all("tr[data-id='new']")[1] do
            fill_in "item[destinations][][contact_groups][][name]", with: new_contact_name2
            fill_in "item[destinations][][contact_groups][][contact_group_name]", with: new_contact_group_name2
            fill_in "item[destinations][][contact_groups][][contact_tel]", with: new_contact_tel2
            fill_in "item[destinations][][contact_groups][][contact_fax]", with: new_contact_fax2
            fill_in "item[destinations][][contact_groups][][contact_email]", with: new_contact_email2
            fill_in "item[destinations][][contact_groups][][contact_link_url]", with: new_contact_link_url2
            fill_in "item[destinations][][contact_groups][][contact_link_name]", with: new_contact_link_name2
          end
        end
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      revision.reload
      expect(revision.changesets).to have(1).items
      revision.changesets.first.tap do |changeset|
        expect(changeset.revision_id).to eq revision.id
        expect(changeset.type).to eq "add"
        expect(changeset.sources).to be_blank
        expect(changeset.destinations).to have(1).items
        changeset.destinations.first.tap do |destination|
          expect(destination[:name]).to eq new_name
          expect(destination[:order]).to eq new_order.to_s
          expect(destination[:ldap_dn]).to eq new_ldap_dn
          expect(destination[:contact_groups]).to have(2).items
          destination[:contact_groups][0].tap do |contact_group|
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq new_contact_name1
            expect(contact_group[:contact_group_name]).to eq new_contact_group_name1
            expect(contact_group[:contact_tel]).to eq new_contact_tel1
            expect(contact_group[:contact_fax]).to eq new_contact_fax1
            expect(contact_group[:contact_email]).to eq new_contact_email1
            expect(contact_group[:contact_link_url]).to eq new_contact_link_url1
            expect(contact_group[:contact_link_name]).to eq new_contact_link_name1
          end
          destination[:contact_groups][1].tap do |contact_group|
            expect(contact_group[:main_state]).to be_blank
            expect(contact_group[:name]).to eq new_contact_name2
            expect(contact_group[:contact_group_name]).to eq new_contact_group_name2
            expect(contact_group[:contact_tel]).to eq new_contact_tel2
            expect(contact_group[:contact_fax]).to eq new_contact_fax2
            expect(contact_group[:contact_email]).to eq new_contact_email2
            expect(contact_group[:contact_link_url]).to eq new_contact_link_url2
            expect(contact_group[:contact_link_name]).to eq new_contact_link_name2
          end
        end
      end

      #
      # Update
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-add" do
        click_on new_name
      end
      expect(page).to have_css("#chorg-after-basic", text: new_name)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        within "#chorg-after-basic" do
          fill_in "item[destinations][][name]", with: new_name2
        end
        within "#chorg-after-contact" do
          within all("tr[data-id]")[0] do
            click_on I18n.t("ss.buttons.delete")
          end
        end
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      revision.reload
      expect(revision.changesets).to have(1).items
      revision.changesets.first.tap do |changeset|
        expect(changeset.revision_id).to eq revision.id
        expect(changeset.type).to eq "add"
        expect(changeset.sources).to be_blank
        expect(changeset.destinations).to have(1).items
        changeset.destinations.first.tap do |destination|
          expect(destination[:name]).to eq new_name2
          expect(destination[:order]).to eq new_order.to_s
          expect(destination[:ldap_dn]).to eq new_ldap_dn
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups][0].tap do |contact_group|
            expect(contact_group[:main_state]).to be_blank
            expect(contact_group[:name]).to eq new_contact_name2
            expect(contact_group[:contact_group_name]).to eq new_contact_group_name2
            expect(contact_group[:contact_tel]).to eq new_contact_tel2
            expect(contact_group[:contact_fax]).to eq new_contact_fax2
            expect(contact_group[:contact_email]).to eq new_contact_email2
            expect(contact_group[:contact_link_url]).to eq new_contact_link_url2
            expect(contact_group[:contact_link_name]).to eq new_contact_link_name2
          end
        end
      end

      #
      # Delete
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-add" do
        click_on new_name2
      end
      expect(page).to have_css("#chorg-after-basic", text: new_name2)
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
