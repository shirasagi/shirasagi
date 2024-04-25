require 'spec_helper'

describe "member_agents_pages_blog_page", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:member) { cms_member(site: site) }
  let(:layout) { create_cms_layout }
  let!(:node_blog) { create :member_node_blog, cur_site: site, layout: layout }
  let!(:blog_layout) { create :member_blog_layout, cur_site: site, cur_node: node_blog }
  let!(:node_blog_page) do
    create :member_node_blog_page, cur_site: site, cur_node: node_blog, layout: blog_layout, cur_member: member
  end

  let!(:node_mypage) { create :member_node_mypage, cur_site: site, layout: layout }
  let!(:node_my_blog) { create(:member_node_my_blog, cur_site: site, cur_node: node_mypage, layout: layout) }
  let!(:node_login) do
    create(:member_node_login, cur_site: site, layout: layout, form_auth: 'enabled', redirect_url: node_my_blog.url)
  end

  before do
    login_member(site, node_login, member)
  end

  after do
    logout_member(site, node_login, member)
  end

  describe "member/blog_page crud" do
    let(:blog_page_name) { unique_id }
    let(:blog_page_html) { "<b>#{unique_id}</b>" }
    let(:blog_page_name2) { unique_id }

    it do
      visit node_blog.full_url
      click_on node_blog_page.name
      within ".member-blog-pages.pages" do
        expect(page).to have_css(".blog", count: 0)
      end

      #
      # Create
      #
      visit node_my_blog.full_url
      click_on I18n.t('ss.links.new')
      within 'form div.member-blog-page' do
        fill_in 'item[name]', with: blog_page_name
        fill_in_ckeditor 'item[html]', with: blog_page_html

        wait_cbox_open do
          click_on I18n.t("ss.buttons.upload")
        end
      end
      within_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: "keyvisual.jpg")
        first(".user-files .select").click
      end
      within 'form div.member-blog-page' do
        expect(page).to have_css('.file-view', text: "keyvisual.jpg")

        wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
          click_on I18n.t("sns.image_paste")
        end

        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))

      expect(page).to have_css('.member-blog-page tbody .name', text: blog_page_name)
      expect(page).to have_css('.member-blog-page tbody .updated')
      expect(page).to have_css('.member-blog-page tbody .released')
      expect(page).to have_css('.member-blog-page tbody .state', text: I18n.t("ss.options.state.public"))

      expect(Member::BlogPage.all.count).to eq 1
      Member::BlogPage.all.site(site).first.tap do |blog_page|
        expect(blog_page.name).to eq blog_page_name
        expect(blog_page.html).to include blog_page_html
        expect(blog_page.layout_id).to be_blank
        expect(blog_page.body_layout_id).to be_blank
        expect(blog_page.state).to eq "public"
        expect(blog_page.member_id).to eq member.id
        expect(blog_page.file_ids).to have(1).items

        file = Member::File.find(blog_page.file_ids[0])
        expect(file.filename).to eq "keyvisual.jpg"
        expect(file.owner_item_type).to eq blog_page.class.name
        expect(file.owner_item_id).to eq blog_page.id
        expect(file.member_id).to eq member.id
      end

      visit node_blog.full_url
      click_on node_blog_page.name
      within ".member-blog-pages.pages" do
        expect(page).to have_css(".blog", count: 1)
        click_on blog_page_name
      end
      within ".blog.page" do
        expect(page).to have_css("header", text: blog_page_name)
        expect(page).to have_css("header", text: I18n.l(node_blog_page.released.to_date, format: :long))
      end

      #
      # Update
      #
      visit node_my_blog.full_url
      click_on blog_page_name
      click_on I18n.t("ss.links.edit")
      within 'form div.member-blog-page' do
        fill_in 'item[name]', with: blog_page_name2

        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))

      expect(page).to have_css('.member-blog-page tbody .name', text: blog_page_name2)
      expect(page).to have_css('.member-blog-page tbody .updated')
      expect(page).to have_css('.member-blog-page tbody .released')
      expect(page).to have_css('.member-blog-page tbody .state', text: I18n.t("ss.options.state.public"))

      expect(Member::BlogPage.all.count).to eq 1
      Member::BlogPage.all.site(site).first.tap do |blog_page|
        expect(blog_page.name).to eq blog_page_name2
      end

      visit node_blog.full_url
      click_on node_blog_page.name
      within ".member-blog-pages.pages" do
        expect(page).to have_css(".blog", count: 1)
        click_on blog_page_name2
      end
      within ".blog.page" do
        expect(page).to have_css("header", text: blog_page_name2)
        expect(page).to have_css("header", text: I18n.l(node_blog_page.released.to_date, format: :long))
      end

      #
      # Close
      #
      visit node_my_blog.full_url
      click_on blog_page_name2
      click_on I18n.t("ss.links.edit")
      within 'form div.member-blog-page' do
        select I18n.t("ss.options.state.closed"), from: 'item[state]'

        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))

      expect(page).to have_css('.member-blog-page tbody .name', text: blog_page_name2)
      expect(page).to have_css('.member-blog-page tbody .updated')
      expect(page).to have_css('.member-blog-page tbody .released')
      expect(page).to have_css('.member-blog-page tbody .state', text: I18n.t("ss.options.state.closed"))

      expect(Member::BlogPage.all.count).to eq 1
      Member::BlogPage.all.site(site).first.tap do |blog_page|
        expect(blog_page.state).to eq "closed"
      end

      visit node_blog.full_url
      click_on node_blog_page.name
      within ".member-blog-pages.pages" do
        expect(page).to have_css(".blog", count: 0)
      end

      #
      # Delete
      #
      visit node_my_blog.full_url
      click_on blog_page_name2
      click_on I18n.t("ss.links.delete")
      within 'form div.member-blog-page' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.deleted"))

      expect(Member::BlogPage.all.count).to eq 0
      expect(History::Trash.all.count).to eq 2
    end
  end
end
