require 'spec_helper'

describe 'members/agents/nodes/bookmark', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:member) { cms_member }
  let(:layout1) { create_cms_layout bookmark_part }
  let(:layout2) { create_cms_layout }

  let!(:mypage_node) { create :member_node_mypage, layout_id: layout2.id }
  let!(:login_node) do
    create(
      :member_node_login,
      layout_id: layout2.id,
      form_auth: 'enabled',
      redirect_url: mypage_node.url)
  end
  let!(:bookmark_node) { create :member_node_bookmark, cur_node: mypage_node, layout_id: layout2.id }
  let!(:bookmark_part) { create :member_part_bookmark, cur_site: site, cur_node: bookmark_node }

  let!(:article_node) { create :article_node_page, cur_node: mypage_node, layout_id: layout1.id }
  let!(:article_page) { create :article_page, cur_node: article_node, layout_id: layout1.id }

  describe 'without member login' do
    it do
      visit article_page.url
      within ".favorite" do
        click_on I18n.t("member.links.register_bookmark")
      end

      within 'form.form-login' do
        fill_in 'item[email]', with: member.email
        fill_in 'item[password]', with: member.in_password
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq article_page.url
      expect(page).to have_css(".favorite", text: I18n.t("member.links.register_bookmark"))
      logout_member(site, login_node)
    end
  end

  describe 'with member login' do
    before do
      login_member(site, login_node)
    end

    after do
      logout_member(site, login_node)
    end

    it do
      visit article_page.url
      within ".favorite" do
        click_on I18n.t("member.links.register_bookmark")
      end
      expect(page).to have_css(".favorite", text: I18n.t("member.links.cancel_bookmark"))

      visit bookmark_node.url
      within ".member-bookmarks" do
        expect(page).to have_link(article_page.name)
        expect(page).to have_link(I18n.t("member.links.cancel_bookmark"))
        click_link article_page.name
      end
      expect(page).to have_css(".favorite", text: I18n.t("member.links.cancel_bookmark"))

      within ".favorite" do
        click_on I18n.t("member.links.cancel_bookmark")
      end
      expect(page).to have_css(".favorite", text: I18n.t("member.links.register_bookmark"))

      visit bookmark_node.url
      within ".member-bookmarks" do
        expect(page).to have_no_link(article_page.name)
      end
    end

    it do
      visit article_page.url
      within ".favorite" do
        click_on I18n.t("member.links.register_bookmark")
      end
      expect(page).to have_css(".favorite", text: I18n.t("member.links.cancel_bookmark"))

      visit bookmark_node.url
      within ".member-bookmarks" do
        expect(page).to have_link(article_page.name)
        expect(page).to have_link(I18n.t("member.links.cancel_bookmark"))
        click_link I18n.t("member.links.cancel_bookmark")
      end
      within ".member-bookmarks" do
        expect(page).to have_no_link(article_page.name)
      end
    end
  end
end
