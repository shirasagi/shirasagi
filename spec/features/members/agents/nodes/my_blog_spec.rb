require 'spec_helper'

describe 'members/agents/nodes/my_blog', type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node_blog) { create :member_node_blog, cur_site: site, layout_id: layout.id }
  let(:node_mypage) { create :member_node_mypage, cur_site: site, layout_id: layout.id }
  let(:node_my_blog) { create(:member_node_my_blog, cur_site: site, cur_node: node_mypage, layout_id: layout.id) }
  let!(:node_login) do
    create(
      :member_node_login,
      cur_site: site,
      layout_id: layout.id,
      form_auth: 'enabled',
      redirect_url: node_my_blog.url)
  end
  let!(:blog_layout) { create :member_blog_layout, cur_site: site, cur_node: node_blog }
  let(:index_url) { node_my_blog.full_url }

  describe 'without member login' do
    it do
      visit index_url

      within 'form.form-login' do
        expect(page).to have_css('input#item_email')
        expect(page).to have_css('input#item_password')
      end
    end
  end

  describe 'with member login' do
    before do
      login_member(site, node_login)
    end

    after do
      logout_member(site, node_login)
    end

    describe 'create new blog and create new blog page' do
      let(:blog_name) { unique_id }
      let(:blog_url) { unique_id }
      let(:blog_page_name) { unique_id }
      let(:blog_page_html) { "<b>#{unique_id}</b>" }

      it do
        visit index_url

        within 'form div.member-blog' do
          fill_in 'item[name]', with: blog_name
          fill_in 'item[basename]', with: blog_url

          click_button '保存'
        end

        click_link '新規作成'

        within 'form div.member-blog-page' do
          fill_in 'item[name]', with: blog_page_name
          fill_in 'item[html]', with: blog_page_html

          click_button '保存'
        end

        expect(page).to have_css('.member-blog-page tbody .name', text: blog_page_name)
        expect(page).to have_css('.member-blog-page tbody .updated')
        expect(page).to have_css('.member-blog-page tbody .released')
        expect(page).to have_css('.member-blog-page tbody .state', text: '公開')

        expect(Member::BlogPage.site(site).count).to eq 1
        blog_page = Member::BlogPage.site(site).first
        expect(blog_page.name).to eq blog_page_name
        expect(blog_page.html).to eq blog_page_html

        click_link blog_page_name

        expect(page).to have_css('.page header h2', text: blog_page_name)
        expect(page).to have_css('.page header .released')
        expect(page.find('.page .body').native.inner_html).to include(blog_page_html)

        click_link '削除する'

        expect(page).to have_css('.column dd', text: blog_page_name)
        click_button '削除'

        expect(page).to have_no_css('.member-blog-page tbody .name', text: blog_page_name)
        expect(Member::BlogPage.site(site).count).to eq 0
      end
    end
  end
end
