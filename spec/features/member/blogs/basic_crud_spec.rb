require 'spec_helper'

describe "member_blogs", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:layout) { create(:cms_layout, site: site, name: "blog") }
  let!(:blogs_node) { create_once :member_node_blog, filename: "blogs", name: "blogs", layout: layout }
  let!(:node) { create_once :member_node_blog_page, filename: "blogs/shirasagi-blog", name: "shirasagi-blog", layout: layout }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit member_blog_pages_path(site: site, cid: node)
      within ".list-items" do
        expect(page).to have_css('.list-item .info .up')
      end

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in_ckeditor "item[html]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      expect(Member::BlogPage.site(site).count).to eq 1
      item = Member::BlogPage.site(site).first
      expect(item.name).to eq "sample"
      expect(item.html).to eq "<p>sample</p>"

      visit member_blog_pages_path(site: site, cid: node)
      click_on item.name
      within "#addon-basic" do
        expect(page).to have_css('dd', text: item.name)
      end

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        fill_in_ckeditor "item[html]", with: "modify"
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.name).to eq "modify"
      expect(item.html).to eq "<p>modify</p>"
    end
  end

  describe "workflow" do
    let!(:item) { create(:member_blog_page, cur_node: node) }
    let!(:edit_path) { edit_member_blog_page_path site.id, node, item }

    before { login_cms_user }

    it do
      visit edit_path

      expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
      expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")

      item.update state: 'close'
      visit edit_path
      expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
      expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")

      # not permittedaaa
      role = cms_user.cms_roles[0]
      role.update permissions: role.permissions.reject { |k, v| k =~ /^(release_|close_)/ }

      visit edit_path
      expect(page).to have_no_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
      expect(page).to have_no_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")

      item.update state: 'public'
      visit edit_path
      expect(page).to have_no_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
      expect(page).to have_no_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
    end
  end
end
