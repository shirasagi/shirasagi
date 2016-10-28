require 'spec_helper'

describe "article_pages", dbscope: :example, tmpdir: true, js: true do
  let(:site) { cms_site }
  let(:article_node) { create :article_node_page, cur_site: site }
  let(:html) do
    html = []
    html << "<p>ああああ</p>"
    html << "<p>いいい</p>"
    html << "<p>&nbsp;</p>"
    html << "<p><a href=\"http://example.jp/file\">添付ファイル (PDF: 36kB)</a></p>"
    html.join("\n")
  end
  let(:article_page) { create :article_page, cur_site: site, cur_node: article_node, html: html }
  let(:file1) { tmp_ss_file(contents: '0123456789', user: cms_user) }
  let(:file2) { tmp_ss_file(contents: '0123456789', user: cms_user) }
  let(:file3) { tmp_ss_file(contents: '0123456789', user: cms_user) }

  let(:od_site) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}@example.jp" }
  let!(:dataset_node) { create :opendata_node_dataset, cur_site: od_site }
  let!(:category_node) { create :opendata_node_category, cur_site: od_site }
  let!(:search_dataset) { create :opendata_node_search_dataset, cur_site: od_site }
  let!(:opendata_dataset1) { create(:opendata_dataset, cur_site: od_site, cur_node: dataset_node, name: "[TEST]A") }
  let!(:opendata_dataset2) { create(:opendata_dataset, cur_site: od_site, cur_node: dataset_node, name: "[TEST]B") }

  before do
    article_node.opendata_site_ids = [ od_site.id ]
    article_node.save!

    path = Rails.root.join("spec", "fixtures", "ss", "logo.png")
    Fs::UploadedFile.create_from_file(path, basename: "spec") do |file|
      create :opendata_license, cur_site: od_site, default_state: 'default', in_file: file
    end

    article_page.cur_user = cms_user
    article_page.file_ids = [ file1.id, file2.id, file3.id ]
    article_page.save!
  end

  context "opendata ref/individual resources" do
    before { login_cms_user }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    context "basic" do
      it do
        #
        # individual resources setting
        #
        visit article_pages_path(site, article_node)
        click_on article_page.name
        find('#addon-cms-agents-addons-opendata_ref-resource .addon-head h2').click

        within "div.od-resource-file[data-file-id='#{file2.id}']" do
          expect(page).to have_css('span.od-resource-file-save-status', text: '')
          select I18n.t('cms.options.opendata_resource.existance'), from: "item[opendata_resources][#{file2.id}][state]"
          # click_on I18n.t('cms.apis.opendata_ref.datasets.index')
          find('a', text: I18n.t('cms.apis.opendata_ref.datasets.index')).trigger('click')
        end
        click_on opendata_dataset1.name
        within "div.od-resource-file[data-file-id='#{file2.id}']" do
          expect(page).to have_css('.ajax-selected td', text: opendata_dataset1.name)
          # click_on I18n.t('views.button.save')
          find('input.od-resource-file-save').trigger('click')
          expect(page).to have_css('.od-resource-file-save-status', text: I18n.t('views.notice.saved'))
        end

        within "div.od-resource-file[data-file-id='#{file3.id}']" do
          expect(page).to have_css('span.od-resource-file-save-status', text: '')
          select I18n.t('cms.options.opendata_resource.none'), from: "item[opendata_resources][#{file3.id}][state]"
          # click_on I18n.t('views.button.save')
          find('input.od-resource-file-save').trigger('click')
          expect(page).to have_css('.od-resource-file-save-status', text: I18n.t('views.notice.saved'))
        end

        #
        # activate opendata integration
        #
        visit article_pages_path(site, article_node)
        click_on article_page.name
        click_on I18n.t('views.links.edit')

        within '#addon-cms-agents-addons-opendata_ref-dataset' do
          find('.addon-head h2').click
          # wait for appearing select
          expect(page).to have_css('a.ajax-box', text: I18n.t('cms.apis.opendata_ref.datasets.index'))
          # choose 'item_opendata_dataset_state_public'
          find('input#item_opendata_dataset_state_public').trigger('click')
        end
        click_on I18n.t('views.button.publish_save')

        expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'))
        article_page.reload
        expect(article_page.state).to eq 'public'
        expect(article_page.opendata_dataset_state).to eq 'public'

        Opendata::Dataset.site(od_site).and_associated_page(article_page).first.tap do |dataset|
          expect(dataset.name).to eq article_page.name
          expect(dataset.parent.id).to eq dataset_node.id
          expect(dataset.state).to eq 'public'
          expect(dataset.text).to include('ああああ')
          expect(dataset.text).to include('いいい')
          expect(dataset.text).to include('添付ファイル (PDF: 36kB)')
          expect(dataset.text).not_to include('<p>')
          expect(dataset.text).not_to include('<a>')
          expect(dataset.text).not_to include('&nbsp;')
          expect(dataset.assoc_site_id).to eq article_page.site.id
          expect(dataset.assoc_node_id).to eq article_page.parent.id
          expect(dataset.assoc_page_id).to eq article_page.id
          expect(dataset.assoc_method).to eq 'auto'
          expect(dataset.resources.count).to eq 1
          dataset.resources.first.tap do |resource|
            expect(resource.name).to eq file1.name
            expect(resource.content_type).to eq file1.content_type
            expect(resource.file_id).not_to eq file1.id
            expect(resource.license_id).not_to be_nil
            expect(resource.assoc_site_id).to eq article_page.site.id
            expect(resource.assoc_node_id).to eq article_page.parent.id
            expect(resource.assoc_page_id).to eq article_page.id
            expect(resource.assoc_filename).to eq file1.filename
            expect(resource.assoc_method).to eq 'auto'
          end
        end

        opendata_dataset1.reload
        expect(opendata_dataset1.assoc_site_id).to be_nil
        expect(opendata_dataset1.assoc_node_id).to be_nil
        expect(opendata_dataset1.assoc_page_id).to be_nil
        expect(opendata_dataset1.assoc_method).to eq 'auto'
        expect(opendata_dataset1.resources.count).to eq 1
        opendata_dataset1.resources.first.tap do |resource|
          expect(resource.name).to eq file2.name
          expect(resource.content_type).to eq file2.content_type
          expect(resource.file_id).not_to eq file2.id
          expect(resource.license_id).not_to be_nil
          expect(resource.assoc_site_id).to eq article_page.site.id
          expect(resource.assoc_node_id).to eq article_page.parent.id
          expect(resource.assoc_page_id).to eq article_page.id
          expect(resource.assoc_filename).to eq file2.filename
          expect(resource.assoc_method).to eq 'auto'
        end

        opendata_dataset2.reload
        expect(opendata_dataset2.assoc_site_id).to be_nil
        expect(opendata_dataset2.assoc_node_id).to be_nil
        expect(opendata_dataset2.assoc_page_id).to be_nil
        expect(opendata_dataset2.assoc_method).to eq 'auto'
        expect(opendata_dataset2.resources.count).to eq 0

        #
        # close an article page
        #
        visit article_pages_path(site, article_node)
        click_on article_page.name
        click_on I18n.t('views.links.edit')

        click_on I18n.t('views.button.draft_save')

        expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'))
        article_page.reload
        expect(article_page.state).to eq 'closed'
        expect(article_page.opendata_dataset_state).to eq 'public'

        Opendata::Dataset.site(od_site).and_associated_page(article_page).first.tap do |dataset|
          expect(dataset.state).to eq 'closed'
          expect(dataset.assoc_site_id).to eq article_page.site.id
          expect(dataset.assoc_node_id).to eq article_page.parent.id
          expect(dataset.assoc_page_id).to eq article_page.id
          expect(dataset.resources.count).to eq 0
        end

        opendata_dataset1.reload
        expect(opendata_dataset1.assoc_site_id).to be_nil
        expect(opendata_dataset1.assoc_node_id).to be_nil
        expect(opendata_dataset1.assoc_page_id).to be_nil
        expect(opendata_dataset1.assoc_method).to eq 'auto'
        expect(opendata_dataset1.resources.count).to eq 0

        opendata_dataset2.reload
        expect(opendata_dataset2.assoc_site_id).to be_nil
        expect(opendata_dataset2.assoc_node_id).to be_nil
        expect(opendata_dataset2.assoc_page_id).to be_nil
        expect(opendata_dataset2.assoc_method).to eq 'auto'
        expect(opendata_dataset2.resources.count).to eq 0
      end
    end

    context "after associated with resource, move attachment file to another dataset" do
      it do
        #
        # individual resources setting
        #
        visit article_pages_path(site, article_node)
        click_on article_page.name
        find('#addon-cms-agents-addons-opendata_ref-resource .addon-head h2').click

        within "div.od-resource-file[data-file-id='#{file2.id}']" do
          expect(page).to have_css('span.od-resource-file-save-status', text: '')
          select I18n.t('cms.options.opendata_resource.existance'), from: "item[opendata_resources][#{file2.id}][state]"
          # click_on I18n.t('cms.apis.opendata_ref.datasets.index')
          find('a', text: I18n.t('cms.apis.opendata_ref.datasets.index')).trigger('click')
        end
        click_on opendata_dataset1.name
        within "div.od-resource-file[data-file-id='#{file2.id}']" do
          # click_on I18n.t('views.button.save')
          find('input.od-resource-file-save').trigger('click')
          expect(page).to have_css('.od-resource-file-save-status', text: I18n.t('views.notice.saved'))
        end

        within "div.od-resource-file[data-file-id='#{file3.id}']" do
          expect(page).to have_css('span.od-resource-file-save-status', text: '')
          select I18n.t('cms.options.opendata_resource.none'), from: "item[opendata_resources][#{file3.id}][state]"
          # click_on I18n.t('views.button.save')
          find('input.od-resource-file-save').trigger('click')
          expect(page).to have_css('.od-resource-file-save-status', text: I18n.t('views.notice.saved'))
        end

        #
        # activate opendata integration
        #
        visit article_pages_path(site, article_node)
        click_on article_page.name
        click_on I18n.t('views.links.edit')

        within '#addon-cms-agents-addons-opendata_ref-dataset' do
          find('.addon-head h2').click
          # wait for appearing select
          expect(page).to have_css('a.ajax-box', text: I18n.t('cms.apis.opendata_ref.datasets.index'))
          # choose 'item_opendata_dataset_state_public'
          find('input#item_opendata_dataset_state_public').trigger('click')
        end
        click_on I18n.t('views.button.publish_save')

        expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'))
        article_page.reload
        expect(article_page.state).to eq 'public'
        expect(article_page.opendata_dataset_state).to eq 'public'

        Opendata::Dataset.site(od_site).and_associated_page(article_page).first.tap do |dataset|
          expect(dataset.name).to eq article_page.name
          expect(dataset.parent.id).to eq dataset_node.id
          expect(dataset.state).to eq 'public'
          expect(dataset.text).to include('ああああ')
          expect(dataset.text).to include('いいい')
          expect(dataset.text).to include('添付ファイル (PDF: 36kB)')
          expect(dataset.text).not_to include('<p>')
          expect(dataset.text).not_to include('<a>')
          expect(dataset.text).not_to include('&nbsp;')
          expect(dataset.assoc_site_id).to eq article_page.site.id
          expect(dataset.assoc_node_id).to eq article_page.parent.id
          expect(dataset.assoc_page_id).to eq article_page.id
          expect(dataset.assoc_method).to eq 'auto'
          expect(dataset.resources.count).to eq 1
          dataset.resources.first.tap do |resource|
            expect(resource.name).to eq file1.name
            expect(resource.content_type).to eq file1.content_type
            expect(resource.file_id).not_to eq file1.id
            expect(resource.license_id).not_to be_nil
            expect(resource.assoc_site_id).to eq article_page.site.id
            expect(resource.assoc_node_id).to eq article_page.parent.id
            expect(resource.assoc_page_id).to eq article_page.id
            expect(resource.assoc_filename).to eq file1.filename
            expect(resource.assoc_method).to eq 'auto'
          end
        end

        opendata_dataset1.reload
        expect(opendata_dataset1.assoc_site_id).to be_nil
        expect(opendata_dataset1.assoc_node_id).to be_nil
        expect(opendata_dataset1.assoc_page_id).to be_nil
        expect(opendata_dataset1.assoc_method).to eq 'auto'
        expect(opendata_dataset1.resources.count).to eq 1
        opendata_dataset1.resources.first.tap do |resource|
          expect(resource.name).to eq file2.name
          expect(resource.content_type).to eq file2.content_type
          expect(resource.file_id).not_to eq file2.id
          expect(resource.license_id).not_to be_nil
          expect(resource.assoc_site_id).to eq article_page.site.id
          expect(resource.assoc_node_id).to eq article_page.parent.id
          expect(resource.assoc_page_id).to eq article_page.id
          expect(resource.assoc_filename).to eq file2.filename
          expect(resource.assoc_method).to eq 'auto'
        end

        opendata_dataset2.reload
        expect(opendata_dataset2.assoc_site_id).to be_nil
        expect(opendata_dataset2.assoc_node_id).to be_nil
        expect(opendata_dataset2.assoc_page_id).to be_nil
        expect(opendata_dataset2.assoc_method).to eq 'auto'
        expect(opendata_dataset2.resources.count).to eq 0

        #
        # move file2 to another dataset
        #
        visit article_pages_path(site, article_node)
        click_on article_page.name
        find('#addon-cms-agents-addons-opendata_ref-resource .addon-head h2').click

        within "div.od-resource-file[data-file-id='#{file2.id}']" do
          expect(page).to have_css('span.od-resource-file-save-status', text: '')
          # click_on I18n.t('cms.apis.opendata_ref.datasets.index')
          find('a', text: I18n.t('cms.apis.opendata_ref.datasets.index')).trigger('click')
        end
        click_on opendata_dataset2.name
        within "div.od-resource-file[data-file-id='#{file2.id}']" do
          expect(page).to have_css('.ajax-selected td', text: opendata_dataset2.name)
          # click_on I18n.t('views.button.save')
          find('input.od-resource-file-save').trigger('click')
          expect(page).to have_css('.od-resource-file-save-status', text: I18n.t('views.notice.saved'))
        end

        opendata_dataset1.reload
        expect(opendata_dataset1.assoc_site_id).to be_nil
        expect(opendata_dataset1.assoc_node_id).to be_nil
        expect(opendata_dataset1.assoc_page_id).to be_nil
        expect(opendata_dataset1.assoc_method).to eq 'auto'
        expect(opendata_dataset1.resources.count).to eq 0

        opendata_dataset2.reload
        expect(opendata_dataset2.assoc_site_id).to be_nil
        expect(opendata_dataset2.assoc_node_id).to be_nil
        expect(opendata_dataset2.assoc_page_id).to be_nil
        expect(opendata_dataset2.assoc_method).to eq 'auto'
        expect(opendata_dataset2.resources.count).to eq 1
        opendata_dataset2.resources.first.tap do |resource|
          expect(resource.name).to eq file2.name
          expect(resource.content_type).to eq file2.content_type
          expect(resource.file_id).not_to eq file2.id
          expect(resource.license_id).not_to be_nil
          expect(resource.assoc_site_id).to eq article_page.site.id
          expect(resource.assoc_node_id).to eq article_page.parent.id
          expect(resource.assoc_page_id).to eq article_page.id
          expect(resource.assoc_filename).to eq file2.filename
          expect(resource.assoc_method).to eq 'auto'
        end
      end
    end
  end
end
