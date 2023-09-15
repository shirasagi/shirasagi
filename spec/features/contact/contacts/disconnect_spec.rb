require 'spec_helper'

describe Contact::ContactsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:group) do
    create(
      :contact_group, name: "#{group0.name}/#{unique_id}",
      contact_groups: [
        {
          name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          main_state: "main"
        },
        {
          name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        }
      ]
    )
  end
  let!(:main_contact) { group.contact_groups.where(main_state: "main").first }
  let!(:sub_contact) { group.contact_groups.ne(main_state: "main").first }

  let(:layout) { create_cms_layout(cur_site: site) }
  let!(:node) { create :article_node_page, cur_site: site, layout: layout, page_layout: layout }

  before do
    login_cms_user
  end

  context "when pages' contact is forcibly disconnected" do
    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: unique_id

        ensure_addon_opened "#addon-contact-agents-addons-page"
        within "#addon-contact-agents-addons-page" do
          wait_cbox_open { click_on I18n.t("contact.apis.contacts.index") }
        end
      end
      wait_for_cbox do
        wait_cbox_close { click_on sub_contact.name }
      end
      within "form#item-form" do
        within "#addon-contact-agents-addons-page" do
          expect(page).to have_css(".ajax-selected [data-id='#{group.id}:#{sub_contact.id}']", text: group.section_name)
          select I18n.t("contact.options.relation.related.title"), from: "item[contact_group_relation]"
        end

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Article::Page.count).to eq 1
      article_page = Article::Page.first
      expect(article_page.contact_group_id).to eq group.id
      expect(article_page.contact_group_contact_id).to eq sub_contact.id
      expect(article_page.contact_group_relation).to eq "related"
      # 強制的に連携が切れた際に備え、ページに複製を保持しているはず
      expect(article_page.contact_charge).to eq sub_contact.contact_group_name
      expect(article_page.contact_tel).to eq sub_contact.contact_tel
      expect(article_page.contact_fax).to eq sub_contact.contact_fax
      expect(article_page.contact_email).to eq sub_contact.contact_email
      expect(article_page.contact_link_url).to eq sub_contact.contact_link_url
      expect(article_page.contact_link_name).to eq sub_contact.contact_link_name

      ::FileUtils.rm_f(article_page.path)

      visit article_page.full_url
      within "#main.page" do
        within ".contact" do
          expect(page).to have_css(".group", text: sub_contact.contact_group_name)
          expect(page).to have_css(".charge", text: sub_contact.contact_group_name)
          expect(page).to have_css(".tel", text: sub_contact.contact_tel)
          expect(page).to have_css(".fax", text: sub_contact.contact_fax)
          expect(page).to have_css(".email", text: sub_contact.contact_email)
          expect(page).to have_css(".link", text: sub_contact.contact_link_name)
        end
      end

      # 組織変更の設定不良などにより、グループの連絡先が削除され、ページとの連携が強制的に切れてしまったケースをシミュレーションする
      sub_contact.delete
      Cms::Group.find(group.id).tap do |group1|
        expect(group1.contact_groups.count).to eq 1
        contact = group1.contact_groups.first
        expect(contact.id).to eq main_contact.id
      end

      visit article_page.full_url
      within "#main.page" do
        within ".contact" do
          # ページに保持している複製を用いて、連絡先がレンダリングされれているはず
          expect(page).to have_css(".group", text: article_page.contact_charge)
          expect(page).to have_css(".charge", text: article_page.contact_charge)
          expect(page).to have_css(".tel", text: article_page.contact_tel)
          expect(page).to have_css(".fax", text: article_page.contact_fax)
          expect(page).to have_css(".email", text: article_page.contact_email)
          expect(page).to have_css(".link", text: article_page.contact_link_name)
        end
      end
    end
  end
end
