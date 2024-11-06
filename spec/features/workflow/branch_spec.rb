require 'spec_helper'

describe "workflow_branch", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:old_name) { "[TEST] br_page" }
  let(:old_index_name) { "[TEST] br_page" }
  let(:new_name) { "[TEST] br_replace" }

  before do
    role = cms_role
    role.permissions = role.permissions - %w(edit_cms_ignore_alert delete_cms_ignore_alert)
    role.save!

    login_cms_user
  end

  shared_examples "create_branch" do
    it do
      # create_branch
      visit show_path
      within "#addon-workflow-agents-addons-branch" do
        wait_for_turbo_frame "#workflow-branch-frame"
        wait_for_event_fired "turbo:frame-load" do
          click_button I18n.t('workflow.create_branch')
        end

        # wait branch created
        expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
        expect(page).to have_css('.see.branch', text: old_name)
        click_link old_name
      end
      within "#addon-workflow-agents-addons-branch" do
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css('.see.master', text: I18n.t('workflow.branch_message'))
      end
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      check_task

      item.reload
      expect(item.state).to eq "public"
      expect(item.master?).to be_truthy
      expect(item.branch?).to be_falsey
      expect(item.branches.count).to eq 1

      branch = item.branches.first
      expect(branch.name).to eq item.name
      expect(branch.index_name).to eq item.index_name
      expect(branch.state).to eq "closed"
      expect(branch.master?).to be_falsey
      expect(branch.branch?).to be_truthy

      if item.class.fields.key?("file_ids")
        expect(branch.files.count).to eq item.files.count
        expect(branch.files.pluck(:id) & item.files.pluck(:id)).to eq item.files.pluck(:id)

        expect(item.html).to include(item.files.first.url)
        expect(branch.html).to include(branch.files.first.url)
        expect(branch.html).to include(item.files.first.url)
        expect(branch.html).to eq item.html
      end

      # draft save
      click_on I18n.t('ss.links.edit')
      within "#item-form" do
        fill_in "item[name]", with: new_name
        fill_in "item[index_name]", with: "" if !item.is_a?(ImageMap::Page)
        click_on I18n.t('ss.buttons.draft_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_turbo_frame "#workflow-branch-frame"
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      item.reload
      branch.reload

      expect(item.state).to eq "public"
      expect(branch.name).not_to eq item.name
      expect(branch.name).to eq new_name
      if !item.is_a?(ImageMap::Page)
        expect(branch.index_name).not_to eq item.index_name
        expect(branch.index_name).to be_blank
      end
      expect(branch.state).to eq "closed"
      expect(item.branches.first.id).to eq(branch.id)

      # publish_branch
      branch_url = show_path.sub(/\/\d+$/, "/#{branch.id}")
      visit branch_url
      wait_for_turbo_frame "#workflow-branch-frame"
      expect(page).to have_css('.see.master', text: I18n.t('workflow.branch_message'))
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      new_html = [].then do |array|
        array << "<p>#{unique_id}</p>"
        if branch.class.fields.key?("file_ids")
          branch.files.first.tap do |file|
            array << "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
          end
        end
        array.join("\r\n\r\n")
      end

      # publish branch
      click_on I18n.t('ss.links.edit')
      within "#item-form" do
        if item.class.fields.key?("html")
          fill_in_ckeditor "item[html]", with: new_html
        end

        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      check_task

      # master was replaced
      expect { branch.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      item.reload
      expect(item.name).to eq branch.name
      if !item.is_a?(ImageMap::Page)
        expect(item.index_name).to eq branch.index_name
      end
      if item.class.fields.key?("html")
        expect(item.html).to eq new_html
      end
      expect(item.state).to eq "public"
      if item.class.fields.key?("file_ids")
        expect(item.file_ids).to eq branch.file_ids
      end
      expect(item.class.all.size).to eq 1

      if item.route == "cms/page"
        wait_for_turbo_frame "#cms-nodes-tree-frame"
      end
    end
  end

  def check_task
    expect(SS::Task.count).to eq 1
    SS::Task.first.tap do |task|
      expect(task.name).to eq "cms_pages:#{item.id}"
      expect(task.state).to eq "completed"
      task.destroy
    end
  end

  context "cms page" do
    let(:file) do
      tmp_ss_file(site: site, user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:html) do
      [
        "<p>テスト</p>",
        "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
      ].join("\r\n\r\n")
    end
    let!(:item) do
      create(
        :cms_page, cur_user: cms_user, filename: "page.html", name: old_name, index_name: old_index_name,
        html: html, file_ids: [ file.id ]
      )
    end
    let(:show_path) { cms_page_path site, item }

    it_behaves_like "create_branch"
  end

  context "article page" do
    let(:file) do
      tmp_ss_file(site: site, user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:html) do
      [
        "<p>テスト</p>",
        "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
      ].join("\r\n\r\n")
    end
    let!(:item) do
      create(
        :article_page, cur_user: cms_user, filename: "docs/page.html", name: old_name, index_name: old_index_name,
        html: html, file_ids: [ file.id ]
      )
    end
    let!(:node) { create :article_node_page, filename: "docs", name: "article" }
    let(:show_path) { article_page_path site, node, item }

    it_behaves_like "create_branch"
  end

  context "event page" do
    let(:file) do
      tmp_ss_file(site: site, user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:html) do
      [
        "<p>テスト</p>",
        "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
      ].join("\r\n\r\n")
    end
    let!(:item) do
      create(
        :event_page, cur_user: cms_user, filename: "event/page.html", name: old_name, index_name: old_index_name,
        html: html, file_ids: [ file.id ]
      )
    end
    let!(:node) { create :event_node_page, filename: "event", name: "event" }
    let(:show_path) { event_page_path site, node, item }
    it_behaves_like "create_branch"
  end

  context "faq page" do
    let(:file) do
      tmp_ss_file(site: site, user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:html) do
      [
        "<p>テスト</p>",
        "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
      ].join("\r\n\r\n")
    end
    let!(:item) do
      create(
        :faq_page, cur_user: cms_user, filename: "faq/page.html", name: old_name, index_name: old_index_name,
        html: html, file_ids: [ file.id ]
      )
    end
    let!(:node) { create :faq_node_page, filename: "faq", name: "faq" }
    let(:show_path) { faq_page_path site, node, item }
    it_behaves_like "create_branch"
  end

  context "mail_page page" do
    let(:file) do
      tmp_ss_file(site: site, user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:html) do
      [
        "<p>テスト</p>",
        "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
      ].join("\r\n\r\n")
    end
    let!(:item) do
      create(
        :mail_page_page, cur_user: cms_user, filename: "mail/page.html", name: old_name, index_name: old_index_name,
        html: html, file_ids: [ file.id ]
      )
    end
    let!(:node) { create :mail_page_node_page, filename: "mail", name: "mail" }
    let(:show_path) { mail_page_page_path site, node, item }
    it_behaves_like "create_branch"
  end

  context "sitemap page" do
    let!(:item) { create :sitemap_page, filename: "sitemap/page.html", name: old_name, index_name: old_index_name }
    let!(:node) { create :sitemap_node_page, filename: "sitemap", name: "sitemap" }
    let(:show_path) { sitemap_page_path site, node, item }
    it_behaves_like "create_branch"
  end

  context "image_map page" do
    let(:file) do
      tmp_ss_file(site: site, user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:html) do
      [
        "<p>テスト</p>",
        "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
      ].join("\r\n\r\n")
    end
    let!(:item) do
      create(:image_map_page, cur_node: node, name: old_name, index_name: old_index_name,
        html: html, file_ids: [ file.id ])
    end
    let!(:node) { create :image_map_node_page, filename: "image-map", name: "image-map" }
    let(:show_path) { image_map_page_path site, node, item }
    it_behaves_like "create_branch"
  end

  context "duplicated creating branch protection" do
    let!(:item) { create :article_page, filename: "docs/page.html", name: old_name, index_name: old_index_name }
    let!(:node) { create :article_node_page, filename: "docs", name: "article" }
    let(:show_path) { article_page_path site, node, item }

    before { login_cms_user }

    context "task is already running" do
      let(:task) { SS::Task.create(site_id: site.id, name: "cms_pages:#{item.id}") }

      before do
        expect(task.start).to be_truthy
      end

      it do
        visit show_path

        within "#addon-workflow-agents-addons-branch" do
          wait_for_turbo_frame "#workflow-branch-frame"
          wait_for_event_fired "turbo:frame-load" do
            click_button I18n.t('workflow.create_branch')
          end
        end
        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.other_task_is_running'))
        end
      end
    end
  end

  context "duplicated publishing branch protection" do
    let!(:item) { create :article_page, filename: "docs/page.html", name: old_name, index_name: old_index_name }
    let!(:node) { create :article_node_page, filename: "docs", name: "article" }
    let(:show_path) { article_page_path site, node, item }

    before { login_cms_user }

    context "task is already running" do
      let!(:task) { SS::Task.create(site_id: site.id, name: "cms_pages:#{item.id}") }

      it do
        visit show_path

        within "#addon-workflow-agents-addons-branch" do
          wait_for_turbo_frame "#workflow-branch-frame"
          wait_for_event_fired "turbo:frame-load" do
            click_button I18n.t('workflow.create_branch')
          end

          # wait branch created
          expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
          expect(page).to have_css('.see.branch', text: old_name)
          click_link old_name
        end
        within "#addon-workflow-agents-addons-branch" do
          wait_for_turbo_frame "#workflow-branch-frame"
          expect(page).to have_css('.see.master', text: I18n.t('workflow.branch_message'))
        end
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        task.reload
        expect(task.state).to eq "completed"

        expect(task.start).to be_truthy

        click_on I18n.t('ss.links.edit')
        within "#item-form" do
          if item.class.fields.key?("html")
            fill_in_ckeditor "item[html]", with: "<p>hello</p>"
          end
          click_on I18n.t('ss.buttons.publish_save')
        end

        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.other_task_is_running'))
      end
    end
  end
end
