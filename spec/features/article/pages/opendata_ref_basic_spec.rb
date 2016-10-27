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

  let(:od_site) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}@example.jp" }
  let!(:dataset_node) { create :opendata_node_dataset, cur_site: od_site }
  let!(:category_node) { create :opendata_node_category, cur_site: od_site }
  let!(:search_dataset) { create :opendata_node_search_dataset, cur_site: od_site }

  before do
    article_node.opendata_site_ids = [ od_site.id ]
    article_node.save!

    file = tmp_ss_file(contents: '0123456789', user: cms_user)

    path = Rails.root.join("spec", "fixtures", "ss", "logo.png")
    Fs::UploadedFile.create_from_file(path, basename: "spec") do |file|
      create :opendata_license, cur_site: od_site, default_state: 'default', in_file: file
    end

    article_page.cur_user = cms_user
    article_page.file_ids = [ file.id ]
    article_page.save!
  end

  context "opendata_ref/basic" do
    before { login_cms_user }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it do
      visit article_pages_path(site, article_node)
      click_on article_page.name

      #
      # activate opendata integration
      #
      click_on I18n.t('views.links.edit')

      find('#addon-cms-agents-addons-opendata_ref-dataset .addon-head h2').click
      choose 'item_opendata_dataset_state_public'
      click_on I18n.t('views.button.publish_save')
      click_on I18n.t('views.button.ignore_alert')

      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'))
      article_page.reload
      expect(article_page.state).to eq 'public'
      expect(article_page.opendata_dataset_state).to eq 'public'

      expect(Opendata::Dataset.site(od_site).count).to eq 1
      Opendata::Dataset.site(od_site).first.tap do |dataset|
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
      # close an article page
      #
      visit article_pages_path(site, article_node)
      click_on article_page.name
      click_on I18n.t('views.links.edit')

      click_on I18n.t('views.button.draft_save')
      click_on I18n.t('views.button.ignore_alert')

      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'))
      article_page.reload
      expect(article_page.state).to eq 'closed'
      expect(article_page.opendata_dataset_state).to eq 'public'

      expect(Opendata::Dataset.site(od_site).count).to eq 1
      Opendata::Dataset.site(od_site).first.tap do |dataset|
        expect(dataset.name).to eq article_page.name
        expect(dataset.parent.id).to eq dataset_node.id
        expect(dataset.state).to eq 'closed'
        expect(dataset.text).to include('ああああ')
        expect(dataset.text).to include('いいい')
        expect(dataset.text).to include('添付ファイル (PDF: 36kB)')
        expect(dataset.text).not_to include('<p>')
        expect(dataset.text).not_to include('<a>')
        expect(dataset.text).not_to include('&nbsp;')
        expect(dataset.assoc_site_id).to eq article_page.site.id
        expect(dataset.assoc_node_id).to eq article_page.parent.id
        expect(dataset.assoc_page_id).to eq article_page.id
        expect(dataset.resources.count).to eq 0
      end
    end
  end
end
