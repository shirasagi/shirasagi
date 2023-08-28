require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:article_node) { create :article_node_page, cur_site: site }
  let(:contact_group) { create :contact_group, name: "#{cms_group.name}/#{unique_id}" }
  let(:html) do
    html = []
    html << "<p>ああああ</p>"
    html << "<p>いいい</p>"
    html << "<p>&nbsp;</p>"
    html << "<p><a href=\"http://example.jp/file\">添付ファイル (PDF: 36kB)</a></p>"
    html.join("\n")
  end
  let(:article_page) { create :article_page, cur_site: site, cur_node: article_node, html: html }

  let(:od_site) do
    create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp", group_ids: [ cms_group.id ]
  end
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
    article_page.contact_group = contact_group
    contact_group.contact_groups.first.tap do |contact|
      article_page.contact_group_contact_id = contact.id
      article_page.contact_group_relation = "related"
      article_page.contact_charge = contact.contact_group_name
      article_page.contact_tel = contact.contact_tel
      article_page.contact_fax = contact.contact_fax
      article_page.contact_email = contact.contact_email
      article_page.contact_link_url = contact.contact_link_url
      article_page.contact_link_name = contact.contact_link_name
    end
    article_page.save!
  end

  context "opendata_ref/basic" do
    before { login_cms_user }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it 'public' do
      visit article_pages_path(site, article_node)
      click_on article_page.name

      #
      # activate opendata integration
      #
      click_on I18n.t('ss.links.edit')

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
          expect(resource.state).to eq 'public'
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
        expect(dataset.contact_group_id).to eq contact_group.id
        expect(dataset.contact_group_contact_id).to eq contact_group.contact_groups.first.id
        expect(dataset.contact_group_relation).to eq article_page.contact_group_relation
        expect(dataset.contact_charge).to eq article_page.contact_charge
        expect(dataset.contact_tel).to eq article_page.contact_tel
        expect(dataset.contact_fax).to eq article_page.contact_fax
        expect(dataset.contact_email).to eq article_page.contact_email
        expect(dataset.contact_link_url).to eq article_page.contact_link_url
        expect(dataset.contact_link_name).to eq article_page.contact_link_name
      end

      #
      # close an article page
      #
      visit article_pages_path(site, article_node)
      click_on article_page.name
      click_on I18n.t('ss.links.edit')

      click_on I18n.t('ss.buttons.withdraw')
      expect(page).to have_css('#alertExplanation h2', text: I18n.t('cms.alert'), wait: 60)
      click_on I18n.t('ss.buttons.ignore_alert')
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

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
        expect(dataset.resources.count).to eq 1
        dataset.resources.first.tap do |resource|
          file = article_page.files.first
          expect(resource.state).to eq 'closed'
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
    end

    it 'closed' do
      visit article_pages_path(site, article_node)
      click_on article_page.name

      #
      # activate opendata integration
      #
      click_on I18n.t('ss.links.edit')

      ensure_addon_opened('#addon-cms-agents-addons-opendata_ref-dataset')
      within '#addon-cms-agents-addons-opendata_ref-dataset' do
        # wait for appearing select
        expect(page).to have_css('a.ajax-box', text: I18n.t('cms.apis.opendata_ref.datasets.index'))
        # choose 'item_opendata_dataset_state_closed'
        find('input#item_opendata_dataset_state_closed').click
      end
      within '#addon-cms-agents-addons-file' do
        select Opendata::License.first.name, from: "item_opendata_resources_#{article_page.file_ids.first}_license_ids"
        select I18n.t("cms.options.opendata_resource.same"), from: "item_opendata_resources_#{article_page.file_ids.first}_state"
      end
      click_on I18n.t('ss.buttons.publish_save')
      wait_for_notice I18n.t('ss.notice.saved')

      article_page.reload
      expect(article_page.state).to eq 'public'
      expect(article_page.opendata_dataset_state).to eq 'closed'

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
        expect(dataset.assoc_method).to eq 'auto'
        expect(dataset.resources.count).to eq 1
        dataset.resources.first.tap do |resource|
          file = article_page.files.first
          expect(resource.state).to eq 'public'
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
      click_on I18n.t('ss.links.edit')

      click_on I18n.t('ss.buttons.withdraw')
      expect(page).to have_css('#alertExplanation h2', text: I18n.t('cms.alert'), wait: 60)
      click_on I18n.t('ss.buttons.ignore_alert')
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      article_page.reload
      expect(article_page.state).to eq 'closed'
      expect(article_page.opendata_dataset_state).to eq 'closed'

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
        expect(dataset.resources.count).to eq 1
        dataset.resources.first.tap do |resource|
          file = article_page.files.first
          expect(resource.state).to eq 'closed'
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
    end

    it 'existance' do
      visit article_pages_path(site, article_node)
      click_on article_page.name

      #
      # activate opendata integration
      #
      click_on I18n.t('ss.links.edit')

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
          expect(resource.state).to eq 'public'
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

      click_on I18n.t('ss.links.edit')

      ensure_addon_opened('#addon-cms-agents-addons-opendata_ref-dataset')
      within '#addon-cms-agents-addons-opendata_ref-dataset' do
        # wait for appearing select
        expect(page).to have_css('a.ajax-box', text: I18n.t('cms.apis.opendata_ref.datasets.index'))
        # choose 'item_opendata_dataset_state_public'
        find('input#item_opendata_dataset_state_existance').click
        wait_cbox_open do
          find('a', text: I18n.t('cms.apis.opendata_ref.datasets.index')).click
        end
      end
      wait_cbox_close do
        click_on Opendata::Dataset.site(od_site).first.name
      end
      click_on I18n.t('ss.buttons.publish_save')
      wait_for_notice I18n.t('ss.notice.saved')

      article_page.reload
      expect(article_page.state).to eq 'public'
      expect(article_page.opendata_dataset_state).to eq 'existance'

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
          expect(resource.state).to eq 'public'
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
      click_on I18n.t('ss.links.edit')

      click_on I18n.t('ss.buttons.withdraw')
      expect(page).to have_css('#alertExplanation h2', text: I18n.t('cms.alert'), wait: 60)
      click_on I18n.t('ss.buttons.ignore_alert')
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      article_page.reload
      expect(article_page.state).to eq 'closed'
      expect(article_page.opendata_dataset_state).to eq 'existance'

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
        expect(dataset.resources.count).to eq 1
        dataset.resources.first.tap do |resource|
          file = article_page.files.first
          expect(resource.state).to eq 'closed'
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
    end
  end
end
