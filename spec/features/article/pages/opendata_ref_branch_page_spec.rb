require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:article_node) { create :article_node_page, cur_site: site }
  let(:html) do
    html = []
    html << "<p>ああああ</p>"
    html << "<p>いいい</p>"
    html << "<p>&nbsp;</p>"
    html << "<p><a href=\"http://example.jp/file\">添付ファイル (PDF: 36kB)</a></p>"
    html.join("\n")
  end
  let!(:article_page) { create :article_page, cur_site: site, cur_node: article_node, html: html }

  let!(:od_site) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp" }
  let!(:dataset_node) { create :opendata_node_dataset, cur_site: od_site }
  let!(:category_node) { create :opendata_node_category, cur_site: od_site }
  let!(:search_dataset) { create :opendata_node_search_dataset, cur_site: od_site }

  before do
    article_node.opendata_site_ids = [ od_site.id ]
    article_node.save!

    file = tmp_ss_file(contents: '0123456789', user: cms_user)

    create :opendata_license, cur_site: od_site, default_state: 'default'

    article_page.cur_user = cms_user
    article_page.file_ids = [ file.id ]
    article_page.save!
  end

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  context "opendata_ref/branch_page" do
    before { login_cms_user }

    it do
      expect(Job::Log.count).to eq 1

      visit article_pages_path(site, article_node)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      click_on article_page.name
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      #
      # activate opendata integration
      #
      click_on I18n.t('ss.links.edit')
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      ensure_addon_opened('#addon-cms-agents-addons-opendata_ref-dataset')
      within '#addon-cms-agents-addons-opendata_ref-dataset' do
        # wait for appearing select
        expect(page).to have_css('a.ajax-box', text: I18n.t('cms.apis.opendata_ref.datasets.index'))
        # choose 'item_opendata_dataset_state_public'
        find('input#item_opendata_dataset_state_public').click
      end
      within '#addon-cms-agents-addons-file' do
        select Opendata::License.first.name, from: "item_opendata_resources_#{article_page.file_ids.first}_license_ids"
        select I18n.t("cms.options.opendata_resource.same"), from: "item_opendata_resources_#{article_page.file_ids.first}_state"
      end
      click_on I18n.t('ss.buttons.publish_save')
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      expect(Job::Log.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      article_page.reload
      expect(article_page.state).to eq 'public'
      expect(article_page.opendata_dataset_state).to eq 'public'

      expect(Opendata::Dataset.site(od_site).count).to eq 1
      Opendata::Dataset.site(od_site).first.tap do |dataset|
        expect(dataset.name).to eq article_page.name
        expect(dataset.state).to eq 'public'
        expect(dataset.parent.id).to eq dataset_node.id
        # expect(dataset.state).to eq 'public'
        # expect(dataset.text).to include('ああああ')
        # expect(dataset.text).to include('いいい')
        # expect(dataset.text).to include('添付ファイル (PDF: 36kB)')
        # expect(dataset.text).not_to include('<p>')
        # expect(dataset.text).not_to include('<a>')
        # expect(dataset.text).not_to include('&nbsp;')
        expect(dataset.assoc_site_id).to eq article_page.site.id
        expect(dataset.assoc_node_id).to eq article_page.parent.id
        expect(dataset.assoc_page_id).to eq article_page.id
        expect(dataset.assoc_method).to eq 'auto'
        expect(dataset.resources.count).to eq 1
        dataset.resources.first.tap do |resource|
          file = article_page.files.first
          expect(resource.name).to eq file.name
          expect(resource.content_type).to eq file.content_type
          expect(resource.file_id).not_to eq file.id
          expect(resource.license_id).not_to be_nil
          expect(resource.assoc_site_id).to eq article_page.site.id
          expect(resource.assoc_node_id).to eq article_page.parent.id
          expect(resource.assoc_page_id).to eq article_page.id
          expect(resource.assoc_filename).to eq file.filename
          expect(resource.assoc_method).to eq 'auto'
        end
      end

      #
      # create a branch page and merge it
      #
      visit article_pages_path(site, article_node)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      click_on article_page.name
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within '#addon-workflow-agents-addons-branch' do
        expect do
          wait_for_event_fired "turbo:frame-load" do
            click_on I18n.t('workflow.create_branch')
          end
          expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
          expect(page).to have_css('table.branches')
        end.to output(/#{I18n.t("workflow.branch_page")}/).to_stdout
        click_on article_page.name
      end
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      expect do
        click_on I18n.t('ss.links.edit')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t('ss.buttons.publish_save')
        wait_for_notice I18n.t('ss.notice.saved')
      end.to output(/#{I18n.t("workflow.branch_page")}/).to_stdout
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      # file ids remain in same
      save_file_ids = article_page.file_ids.dup
      article_page.reload
      expect(article_page.file_ids - save_file_ids).to be_blank

      # dataset also remains in same
      expect(Opendata::Dataset.site(od_site).count).to eq 1
      Opendata::Dataset.site(od_site).first.tap do |dataset|
        expect(dataset.name).to eq article_page.name
        expect(dataset.state).to eq 'public'
        expect(dataset.parent.id).to eq dataset_node.id
        expect(dataset.assoc_site_id).to eq article_page.site.id
        expect(dataset.assoc_node_id).to eq article_page.parent.id
        expect(dataset.assoc_page_id).to eq article_page.id
        expect(dataset.assoc_method).to eq 'auto'
        expect(dataset.resources.count).to eq 1
      end

      #
      # create a branch page and merge it, second attempts
      #
      visit article_pages_path(site, article_node)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      click_on article_page.name
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within '#addon-workflow-agents-addons-branch' do
        expect do
          wait_for_event_fired "turbo:frame-load" do
            click_on I18n.t('workflow.create_branch')
          end
          expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
          expect(page).to have_css('table.branches')
        end.to output(/#{I18n.t("workflow.branch_page")}/).to_stdout
        click_on article_page.name
      end
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      click_on I18n.t('ss.links.edit')
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "#item-form" do
        within "#file-#{article_page.file_ids.first}" do
          page.accept_confirm(I18n.t("ss.confirm.delete")) do
            click_on I18n.t("ss.buttons.delete")
          end
        end
        ss_upload_file "#{Rails.root}/spec/fixtures/opendata/resource.pdf"
      end
      expect do
        within "#item-form" do
          within "#addon-cms-agents-addons-file" do
            expect(page).to have_css(".file-view", text: "resource.pdf")
          end
          click_on I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
      end.to output(/#{I18n.t("workflow.branch_page")}/).to_stdout
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      # file ids are completely changed
      save_file_ids = article_page.file_ids.dup
      article_page.reload
      expect(article_page.file_ids - save_file_ids).to eq article_page.file_ids

      expect(Opendata::Dataset.site(od_site).count).to eq 1
      Opendata::Dataset.site(od_site).first.tap do |dataset|
        expect(dataset.name).to eq article_page.name
        expect(dataset.state).to eq 'public'
        expect(dataset.parent.id).to eq dataset_node.id
        expect(dataset.assoc_site_id).to eq article_page.site.id
        expect(dataset.assoc_node_id).to eq article_page.parent.id
        expect(dataset.assoc_page_id).to eq article_page.id
        expect(dataset.assoc_method).to eq 'auto'
        expect(dataset.resources.count).to eq 1
        expect(dataset.resources.and_public.count).to eq 0
      end

      visit article_pages_path(site, article_node)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      click_on article_page.name
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within '#addon-cms-agents-addons-opendata_ref-resource' do
        select Opendata::License.first.name, from: "item_opendata_resources_#{article_page.file_ids.first}_license_id"
        select I18n.t("cms.options.opendata_resource.same"), from: "item_opendata_resources_#{article_page.file_ids.first}_state"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within '#addon-cms-agents-addons-opendata_ref-resource' do
        expect(page).to have_css(".od-resource-file-save-status", text: I18n.t("ss.notice.saved"))
      end

      expect(Job::Log.count).to eq 9
      expect(Opendata::Dataset.site(od_site).count).to eq 1
      Opendata::Dataset.site(od_site).first.tap do |dataset|
        expect(dataset.name).to eq article_page.name
        expect(dataset.state).to eq 'public'
        expect(dataset.parent.id).to eq dataset_node.id
        expect(dataset.assoc_site_id).to eq article_page.site.id
        expect(dataset.assoc_node_id).to eq article_page.parent.id
        expect(dataset.assoc_page_id).to eq article_page.id
        expect(dataset.assoc_method).to eq 'auto'
        expect(dataset.resources.count).to eq 2
        expect(dataset.resources.and_public.count).to eq 1
        dataset.resources.and_public.first.tap do |resource|
          file = article_page.files.first
          expect(resource.name).to eq ::File.basename(file.name, ".*")
          expect(resource.content_type).to eq file.content_type
          expect(resource.file_id).not_to eq file.id
          expect(resource.license_id).not_to be_nil
          expect(resource.assoc_site_id).to eq article_page.site.id
          expect(resource.assoc_node_id).to eq article_page.parent.id
          expect(resource.assoc_page_id).to eq article_page.id
          expect(resource.assoc_filename).to eq file.filename
          expect(resource.assoc_method).to eq 'auto'
        end
      end
    end
  end
end
