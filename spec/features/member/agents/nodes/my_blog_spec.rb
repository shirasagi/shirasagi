require 'spec_helper'

describe 'members/agents/nodes/my_blog', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node_blog) { create :member_node_blog, cur_site: site, layout: layout }
  let(:node_mypage) { create :member_node_mypage, cur_site: site, layout: layout }
  let(:node_my_blog) { create(:member_node_my_blog, cur_site: site, cur_node: node_mypage, layout: layout) }
  let!(:node_login) do
    create(
      :member_node_login,
      cur_site: site,
      layout: layout,
      form_auth: 'enabled',
      redirect_url: node_my_blog.url)
  end
  let!(:blog_layout) { create :member_blog_layout, cur_site: site, cur_node: node_blog }

  describe 'without member login' do
    it do
      visit node_my_blog.full_url

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

    describe "member/node/blog_page's crud" do
      let(:blog_name) { unique_id }
      let(:blog_url) { unique_id }
      let(:blog_description) { Array.new(2) { unique_id } }
      let(:blog_genres) { Array.new(2) { unique_id } }
      let(:blog_name2) { unique_id }

      it do
        visit node_blog.full_url
        within ".member-blogs" do
          expect(page).to have_css(".blog", count: 0)
        end

        #
        # Create
        #
        visit node_my_blog.full_url

        within 'form div.member-blog' do
          fill_in 'item[name]', with: blog_name
          fill_in 'item[basename]', with: blog_url
          attach_file "item[in_image]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          fill_in 'item[description]', with: blog_description.join("\n")
          fill_in 'item[genres]', with: blog_genres.join("\n")

          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))

        expect(Member::Node::BlogPage.all.count).to eq 1
        Member::Node::BlogPage.all.site(site).first.tap do |node|
          expect(node.name).to eq blog_name
          expect(node.basename).to eq blog_url
          expect(node.layout_id).to eq blog_layout.id
          expect(node.state).to eq "public"
          expect(node.member_id).to eq cms_member(site: site).id
          expect(node.image).to be_present
          expect(node.description).to eq blog_description.join("\r\n")
          expect(node.genres).to eq blog_genres

          image = Member::File.find(node.image_id)
          expect(image.filename).to eq "logo.png"
          expect(image.owner_item_type).to eq node.class.name
          expect(image.owner_item_id).to eq node.id
          expect(image.member_id).to be_blank
        end

        visit node_blog.full_url
        within ".member-blogs" do
          expect(page).to have_css(".blog", count: 1)
          expect(page).to have_css(".blog", text: blog_name)
        end

        #
        # Update and close
        #
        visit node_my_blog.full_url
        click_on I18n.t("member.links.blog_setting")
        within 'form div.member-blog' do
          fill_in 'item[name]', with: blog_name2
          select I18n.t("ss.options.state.closed"), from: 'item[state]'

          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))

        expect(Member::Node::BlogPage.all.count).to eq 1
        Member::Node::BlogPage.all.site(site).first.tap do |node|
          expect(node.name).to eq blog_name2
          expect(node.state).to eq "closed"
        end

        visit node_blog.full_url
        within ".member-blogs" do
          expect(page).to have_css(".blog", count: 0)
        end

        # able to view a attachment file on closed blog page.
        # 非公開のブログページの添付ファイルが閲覧できることを確認
        visit node_my_blog.full_url
        click_on I18n.t("member.links.blog_setting")
        image_element_info(first(".member-blog img")).tap do |info|
          expect(info[:width]).to eq 160
          expect(info[:height]).to eq 160
        end
      end
    end
  end
end
