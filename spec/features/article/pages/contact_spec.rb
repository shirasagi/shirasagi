require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let!(:contact_group1) { create(:contact_group, name: "#{cms_group.name}/#{unique_id}") }
  let!(:contact_group2) { create(:contact_group, name: "#{cms_group.name}/#{unique_id}") }
  let!(:user) { create :cms_test_user, group_ids: [ contact_group1.id ], cms_role_ids: cms_user.cms_role_ids }

  context "contact" do
    before do
      login_user user
    end

    context "default contact group" do
      it do
        visit new_article_page_path(site: site, cid: node)
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        section = first('#addon-contact-agents-addons-page')
        expect(section).to have_text(contact_group1.name)
        expect(section).to have_text(contact_group1.contact_tel)
        expect(section).to have_text(contact_group1.contact_fax)
        expect(section).to have_text(contact_group1.contact_email)
        expect(section).to have_text(contact_group1.contact_postal_code)
        expect(section).to have_text(contact_group1.contact_address)
        expect(section).to have_text(contact_group1.contact_link_url)
        expect(section).to have_text(contact_group1.contact_link_name)

        expect(Article::Page.all.count).to eq 1
        item = Article::Page.all.first
        expect(item.contact_group_id).to eq contact_group1.id
        contact = contact_group1.contact_groups.where(main_state: "main").first
        expect(item.contact_group_contact_id).to eq contact.id
        expect(item.contact_charge).to eq contact.contact_charge
        expect(item.contact_tel).to eq contact.contact_tel
        expect(item.contact_fax).to eq contact.contact_fax
        expect(item.contact_email).to eq contact.contact_email
        expect(item.contact_postal_code).to eq contact.contact_postal_code
        expect(item.contact_address).to eq contact.contact_address
        expect(item.contact_link_url).to eq contact.contact_link_url
        expect(item.contact_link_name).to eq contact.contact_link_name

        visit edit_article_page_path(site: site, cid: node, id: item)
        within "form#item-form" do
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        section = first('#addon-contact-agents-addons-page')
        expect(section).to have_text(contact_group1.name)
        expect(section).to have_text(contact_group1.contact_tel)
        expect(section).to have_text(contact_group1.contact_fax)
        expect(section).to have_text(contact_group1.contact_email)
        expect(section).to have_text(contact_group1.contact_postal_code)
        expect(section).to have_text(contact_group1.contact_address)
        expect(section).to have_text(contact_group1.contact_link_url)
        expect(section).to have_text(contact_group1.contact_link_name)

        expect(Article::Page.all.count).to eq 1
        item = Article::Page.all.first
        expect(item.contact_group_id).to eq contact_group1.id
        contact = contact_group1.contact_groups.where(main_state: "main").first
        expect(item.contact_group_contact_id).to eq contact.id
        expect(item.contact_charge).to eq contact.contact_charge
        expect(item.contact_tel).to eq contact.contact_tel
        expect(item.contact_fax).to eq contact.contact_fax
        expect(item.contact_email).to eq contact.contact_email
        expect(item.contact_postal_code).to eq contact.contact_postal_code
        expect(item.contact_address).to eq contact.contact_address
        expect(item.contact_link_url).to eq contact.contact_link_url
        expect(item.contact_link_name).to eq contact.contact_link_name
      end
    end

    context "change contact group" do
      it do
        visit new_article_page_path(site: site, cid: node)
        wait_for_all_ckeditors_ready
        ensure_addon_opened('#addon-contact-agents-addons-page')
        within '#addon-contact-agents-addons-page' do
          wait_for_cbox_opened do
            click_on I18n.t("contact.apis.contacts.index")
          end
        end

        within_cbox do
          within "[data-group-id='#{contact_group2.id}']" do
            wait_for_cbox_closed { click_on contact_group2.section_name }
          end
        end

        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        section = first('#addon-contact-agents-addons-page')
        expect(section).to have_text(contact_group2.name)
        expect(section).to have_text(contact_group2.contact_group_name)
        expect(section).to have_text(contact_group2.contact_charge)
        expect(section).to have_text(contact_group2.contact_tel)
        expect(section).to have_text(contact_group2.contact_fax)
        expect(section).to have_text(contact_group2.contact_email)
        expect(section).to have_text(contact_group2.contact_postal_code)
        expect(section).to have_text(contact_group2.contact_address)
        expect(section).to have_text(contact_group2.contact_link_url)
        expect(section).to have_text(contact_group2.contact_link_name)

        expect(Article::Page.all.count).to eq 1
        item = Article::Page.all.first
        expect(item.contact_group_id).to eq contact_group2.id
        contact = contact_group2.contact_groups.where(main_state: "main").first
        expect(item.contact_group_contact_id).to eq contact.id
        expect(item.contact_group_name).to eq contact.contact_group_name
        expect(item.contact_charge).to eq contact.contact_charge
        expect(item.contact_tel).to eq contact.contact_tel
        expect(item.contact_fax).to eq contact.contact_fax
        expect(item.contact_email).to eq contact.contact_email
        expect(item.contact_postal_code).to eq contact.contact_postal_code
        expect(item.contact_address).to eq contact.contact_address
        expect(item.contact_link_url).to eq contact.contact_link_url
        expect(item.contact_link_name).to eq contact.contact_link_name

        visit edit_article_page_path(site: site, cid: node, id: item)
        within "form#item-form" do
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_turbo_frame "#workflow-branch-frame"

        section = first('#addon-contact-agents-addons-page')
        expect(section).to have_text(contact_group2.name)
        expect(section).to have_text(contact_group2.contact_group_name)
        expect(section).to have_text(contact_group2.contact_charge)
        expect(section).to have_text(contact_group2.contact_tel)
        expect(section).to have_text(contact_group2.contact_fax)
        expect(section).to have_text(contact_group2.contact_email)
        expect(section).to have_text(contact_group2.contact_postal_code)
        expect(section).to have_text(contact_group2.contact_address)
        expect(section).to have_text(contact_group2.contact_link_url)
        expect(section).to have_text(contact_group2.contact_link_name)

        expect(Article::Page.all.count).to eq 1
        item = Article::Page.all.first
        expect(item.contact_group_id).to eq contact_group2.id
        contact = contact_group2.contact_groups.where(main_state: "main").first
        expect(item.contact_group_contact_id).to eq contact.id
        expect(item.contact_group_name).to eq contact.contact_group_name
        expect(item.contact_charge).to eq contact.contact_charge
        expect(item.contact_tel).to eq contact.contact_tel
        expect(item.contact_fax).to eq contact.contact_fax
        expect(item.contact_email).to eq contact.contact_email
        expect(item.contact_postal_code).to eq contact.contact_postal_code
        expect(item.contact_address).to eq contact.contact_address
        expect(item.contact_link_url).to eq contact.contact_link_url
        expect(item.contact_link_name).to eq contact.contact_link_name
      end
    end
  end
end
