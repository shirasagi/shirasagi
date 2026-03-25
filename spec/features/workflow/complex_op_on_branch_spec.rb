require 'spec_helper'

# ブランチ上での複雑な操作
describe "workflow_branch", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  context "complex operations with branch" do
    let!(:node) { create :article_node_page, cur_site: site, state: "public", group_ids: user.group_ids }
    let!(:file1) do
      content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path, basename: "logo1.png")
    end
    let(:name) { "name-#{unique_id}" }

    it do
      login_user user, to: article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        fill_in "item[name]", with: name

        ss_select_file file1

        wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
          within "#addon-cms-agents-addons-file" do
            within ".file-view" do
              click_on I18n.t("sns.image_paste")
            end
          end
        end

        wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
      end
      within_cbox { click_on I18n.t("ss.buttons.ignore_alert") }
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_all_turbo_frames
      wait_for_all_ckeditors_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      expect(Article::Page.all.count).to eq 1
      master_page = Article::Page.all.first
      expect(master_page.site_id).to eq site.id
      expect(master_page.name).to eq name
      expect(master_page.file_ids).to have(1).items
      expect(master_page.file_ids).to eq [ file1.id ]
      expect(master_page.state).to eq "public"
      file1.reload
      expect(file1.owner_item_id).to eq master_page.id
      expect(file1.owner_item_type).to eq master_page.class.name
      expect(File.size("#{file1.public_dir}/#{file1.filename}")).to be > 10

      visit article_page_path(site: site, cid: node, id: master_page)
      wait_for_all_turbo_frames
      wait_for_all_ckeditors_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      within "#addon-workflow-agents-addons-branch" do
        wait_for_event_fired "turbo:frame-load" do
          click_button I18n.t('workflow.create_branch')
        end

        expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
        expect(page).to have_css('.see.branch', text: name)
      end

      expect(Article::Page.all.count).to eq 2
      branch_page = Article::Page.all.where(master_id: master_page.id).first
      expect(branch_page.site_id).to eq site.id
      expect(branch_page.name).to eq name
      expect(branch_page.file_ids).to have(1).items
      expect(branch_page.file_ids).to eq [ file1.id ]
      expect(branch_page.state).to eq "closed"
      # file1 は master_page と branch_page で共有されているが、所有者は master_page
      file1.reload
      expect(file1.owner_item_id).to eq master_page.id
      expect(file1.owner_item_type).to eq master_page.class.name
      expect(File.size("#{file1.public_dir}/#{file1.filename}")).to be > 10

      visit article_page_path(site: site, cid: node, id: branch_page)
      wait_for_all_turbo_frames
      wait_for_all_ckeditors_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      click_on I18n.t("ss.links.edit")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        insert_in_ckeditor "item[html]", html: "<p>This is a new paragraph.</p>"

        wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
      end
      within_cbox { click_on I18n.t("ss.buttons.ignore_alert") }
      wait_for_notice I18n.t('ss.notice.saved')
      # 差し替えページを公開保存すると一覧に戻ってくるので、次を待つ必要はない
      # wait_for_all_turbo_frames
      # wait_for_all_ckeditors_ready
      # expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      expect { branch_page.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      master_page.reload
      expect(master_page.html).to include("<p>This is a new paragraph.</p>")
      expect(master_page.file_ids).to have(1).items
      expect(master_page.file_ids).to eq [ file1.id ]
      expect(master_page.state).to eq "public"
      file1.reload
      expect(file1.owner_item_id).to eq master_page.id
      expect(file1.owner_item_type).to eq master_page.class.name
      expect(File.size("#{file1.public_dir}/#{file1.filename}")).to be > 10
    end
  end
end
