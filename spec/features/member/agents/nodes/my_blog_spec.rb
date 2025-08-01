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
  let!(:member1) { cms_member(site: site) }

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
    describe "member/node/blog_page's crud" do
      let(:blog_name) { unique_id }
      let(:blog_url) { unique_id }
      let(:blog_description) { Array.new(2) { unique_id } }
      let(:blog_genres) { Array.new(2) { unique_id } }
      let(:blog_name2) { unique_id }

      before do
        login_member(site, node_login, member1)
      end

      after do
        logout_member(site, node_login, member1)
      end

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
        wait_for_notice I18n.t("ss.notice.saved"), selector: "#ss-notice"

        expect(Member::Node::BlogPage.all.count).to eq 1
        Member::Node::BlogPage.all.site(site).first.tap do |node|
          expect(node.name).to eq blog_name
          expect(node.basename).to eq blog_url
          expect(node.filename).to eq "#{node_blog.filename}/#{blog_url}"
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

    describe "member/blog_page's crud" do
      let!(:node_blog_page) do
        create(
          :member_node_blog_page, cur_site: site, cur_node: node_blog, layout: blog_layout, page_layout: blog_layout,
          member: member1, genres: [ unique_id ], state: "public")
      end
      let(:name1) { "name-#{unique_id}" }
      let(:body1) { "body-#{unique_id}" }
      let(:html1) { "<p>#{body1}</p>" }
      let(:name2) { "name-#{unique_id}" }

      before do
        login_member(site, node_login, member1)
      end

      after do
        logout_member(site, node_login, member1)
      end

      it do
        #
        # Create
        #
        visit node_my_blog.full_url
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        within "form.member-blog-page" do
          fill_in "item[name]", with: name1
          fill_in_ckeditor "item[html]", with: html1
          wait_for_cbox_opened { click_on I18n.t("ss.links.upload") }
        end
        within_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_on I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
          wait_for_cbox_closed do
            click_on 'keyvisual.jpg'
          end
        end
        # アップロードされたファイルから作成された一時ファイルをチェック
        expect(SS::File.all.count).to eq 1
        SS::File.all.first.tap do |file|
          file = file.becomes_with_model
          expect(file).to be_a(Member::File)
          expect(file.site_id).to eq site.id
          expect(file.filename).to eq "keyvisual.jpg"
          expect(file.model).to eq "member/temp_file"
          expect(file.owner_item_type).to be_blank
          expect(file.owner_item_id).to be_blank
          expect(file.member_id).to eq member1.id
        end
        # back to blog
        within "form.member-blog-page" do
          within '#selected-files' do
            expect(page).to have_css('.name', text: 'keyvisual.jpg')
            image_element_info(first("img")).tap do |info|
              expect(info[:width]).to eq 360
              expect(info[:height]).to be > 100
            end
          end

          wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
            within '#selected-files' do
              click_on I18n.t("sns.image_paste")
            end
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved"), selector: "#ss-notice"

        expect(Member::BlogPage.all.count).to eq 1
        Member::BlogPage.all.first.tap do |blog_page|
          expect(blog_page.site_id).to eq site.id
          expect(blog_page.member_id).to eq member1.id
          expect(blog_page.filename).to start_with "#{node_blog_page.filename}/"
          expect(blog_page.name).to eq name1
          expect(blog_page.html).to include(body1, "keyvisual.jpg")
          expect(blog_page.files.count).to eq 1
          expect(blog_page.state).to eq "public"

          blog_image = blog_page.files.first
          blog_image = blog_image.becomes_with_model
          expect(blog_image).to be_a(Member::File)
          expect(blog_image.site_id).to eq site.id
          expect(blog_image.filename).to eq "keyvisual.jpg"
          expect(blog_image.model).to eq "member/blog_page"
          expect(blog_image.owner_item_type).to eq blog_page.class.name
          expect(blog_image.owner_item_id).to eq blog_page.id
          expect(blog_image.member_id).to eq member1.id
        end

        #
        # Update
        #
        visit node_my_blog.full_url
        within ".member-blog-page" do
          expect(page).to have_css(".name", text: name1)
        end
        click_on name1
        click_on I18n.t("ss.links.edit")
        within "form.member-blog-page" do
          fill_in "item[name]", with: name2
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved"), selector: "#ss-notice"

        expect(Member::BlogPage.all.count).to eq 1
        Member::BlogPage.all.first.tap do |blog_page|
          expect(blog_page.site_id).to eq site.id
          expect(blog_page.member_id).to eq member1.id
          expect(blog_page.filename).to start_with "#{node_blog_page.filename}/"
          expect(blog_page.name).to eq name2
          expect(blog_page.html).to include(body1, "keyvisual.jpg")
          expect(blog_page.files.count).to eq 1
          expect(blog_page.state).to eq "public"

          blog_image = blog_page.files.first
          blog_image = blog_image.becomes_with_model
          expect(blog_image).to be_a(Member::File)
          expect(blog_image.site_id).to eq site.id
          expect(blog_image.filename).to eq "keyvisual.jpg"
          expect(blog_image.model).to eq "member/blog_page"
          expect(blog_image.owner_item_type).to eq blog_page.class.name
          expect(blog_image.owner_item_id).to eq blog_page.id
          expect(blog_image.member_id).to eq member1.id
        end

        #
        # Delete
        #
        visit node_my_blog.full_url
        within ".member-blog-page" do
          expect(page).to have_css(".name", text: name2)
        end
        click_on name2
        click_on I18n.t("ss.links.delete")
        within "form.member-blog-page" do
          click_on I18n.t("ss.buttons.delete")
        end
        wait_for_notice I18n.t("ss.notice.deleted"), selector: "#ss-notice"

        expect(Member::BlogPage.all.count).to eq 0
      end
    end

    describe "member/blog_page's publish" do
      let!(:member2) { cms_member(site: site, email: unique_email) }
      let!(:node_blog_page) do
        create(
          :member_node_blog_page, cur_site: site, cur_node: node_blog, layout: blog_layout, page_layout: blog_layout,
          member: member1, genres: [ unique_id ], state: "public")
      end
      let(:name1) { "name-#{unique_id}" }
      let(:body1) { "body-#{unique_id}" }
      let(:html1) { "<p>#{body1}</p>" }
      let(:name2) { "name-#{unique_id}" }

      it do
        login_member(site, node_login, member1)

        # Create a blog in private
        visit node_my_blog.full_url
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        within "form.member-blog-page" do
          fill_in "item[name]", with: name1
          fill_in_ckeditor "item[html]", with: html1
          wait_for_cbox_opened { click_on I18n.t("ss.links.upload") }
        end
        within_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_on I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
          wait_for_cbox_closed do
            click_on 'keyvisual.jpg'
          end
        end
        within "form.member-blog-page" do
          within '#selected-files' do
            expect(page).to have_css('.name', text: 'keyvisual.jpg')
            image_element_info(first("img")).tap do |info|
              expect(info[:width]).to eq 360
              expect(info[:height]).to be > 100
            end
          end

          wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
            within '#selected-files' do
              click_on I18n.t("sns.image_paste")
            end
          end

          select I18n.t("ss.options.state.closed"), from: "item[state]"

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved"), selector: "#ss-notice"

        expect(Member::BlogPage.all.count).to eq 1
        Member::BlogPage.all.first.tap do |blog_page|
          expect(blog_page.site_id).to eq site.id
          expect(blog_page.member_id).to eq member1.id
          expect(blog_page.filename).to start_with "#{node_blog_page.filename}/"
          expect(blog_page.name).to eq name1
          expect(blog_page.html).to include(body1, "keyvisual.jpg")
          expect(blog_page.files.count).to eq 1
          expect(blog_page.state).to eq "closed"

          blog_image = blog_page.files.first
          blog_image = blog_image.becomes_with_model
          expect(blog_image).to be_a(Member::File)
          expect(blog_image.site_id).to eq site.id
          expect(blog_image.filename).to eq "keyvisual.jpg"
          expect(blog_image.model).to eq "member/blog_page"
          expect(blog_image.owner_item_type).to eq blog_page.class.name
          expect(blog_image.owner_item_id).to eq blog_page.id
          expect(blog_image.member_id).to eq member1.id
        end

        # 公開側をアクセス
        visit node_blog_page.url
        expect(page).to have_no_content(name1)

        # publish a blog
        visit node_my_blog.full_url
        click_on name1
        click_on I18n.t("ss.links.edit")
        within "form.member-blog-page" do
          select I18n.t("ss.options.state.public"), from: "item[state]"
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved"), selector: "#ss-notice"

        expect(Member::BlogPage.all.count).to eq 1
        Member::BlogPage.all.first.tap do |blog_page|
          expect(blog_page.state).to eq "public"
        end

        # 公開側をアクセス
        visit node_blog_page.url
        within ".pages" do
          expect(page).to have_css(".blog", count: 1)
          within ".blog" do
            expect(page).to have_css("h2", text: name1)

            image_element_info(first(".body img")).tap do |info|
              expect(info[:width]).to eq 712
              expect(info[:height]).to be > 100
            end

            click_on name1
          end
        end

        within ".blog" do
          expect(page).to have_css("h2", text: name1)

          image_element_info(first(".body img")).tap do |info|
            expect(info[:width]).to eq 712
            expect(info[:height]).to be > 100
          end
        end

        # 違うメンバーで公開側をチェック
        login_member(site, node_login, member2)

        visit node_blog_page.url
        within ".pages" do
          expect(page).to have_css(".blog", count: 1)
          within ".blog" do
            expect(page).to have_css("h2", text: name1)

            image_element_info(first(".body img")).tap do |info|
              expect(info[:width]).to eq 712
              expect(info[:height]).to be > 100
            end

            click_on name1
          end
        end

        within ".blog" do
          expect(page).to have_css("h2", text: name1)

          image_element_info(first(".body img")).tap do |info|
            expect(info[:width]).to eq 712
            expect(info[:height]).to be > 100
          end
        end
      end
    end
  end
end
