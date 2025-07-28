require 'spec_helper'

describe 'sys_site_copy', type: :feature, dbscope: :example do
  let(:index_path) { sys_site_copy_path }

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context 'run site copy', js: true do
    let!(:site) { cms_site }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let(:target_host_subdir) { unique_id }

    before do
      login_sys_user
    end

    it do
      visit index_path

      within '#item-form' do
        fill_in 'item[target_host_name]', with: target_host_name
        fill_in 'item[target_host_host]', with: target_host_host
        fill_in 'item[target_host_domains]', with: target_host_domain
        fill_in 'item[target_host_subdir]', with: target_host_subdir
        select site.name

        check 'item_copy_contents_pages'
        check 'item_copy_contents_files'
        check 'item_copy_contents_editor_templates'
        check 'item_copy_contents_dictionaries'
        check 'item_copy_contents_loop_settings'
        check 'item_copy_contents_page_searches'
        check 'item_copy_contents_source_cleaner_templates'
        check 'item_copy_contents_theme_templates'
        check 'item_copy_contents_translate_langs'
        check 'item_copy_contents_translate_text_caches'
        check 'item_copy_contents_word_dictionaries'

        click_on I18n.t("sys.apis.sites.index")
      end

      within 'table.sys-copy' do
        click_on site.name
      end

      within '#item-form' do
        expect(page).to have_css(".ajax-selected", text: site.name)
        within '#addon-basic' do
          expect(page).to have_css('.sys-site-copy')
        end

        click_on I18n.t("ss.buttons.confirm")
      end

      click_on I18n.t("ss.buttons.run")

      wait_for_notice I18n.t("sys.site_copy/started_job"), wait: 60
      expect(current_path).to eq index_path

      within '#addon-basic' do
        expect(page).to have_css('.sys-site-copy-show')
      end

      expect(Sys::SiteCopyTask.count).to eq 1
      Sys::SiteCopyTask.first.tap do |task|
        expect(task.target_host_name).to eq target_host_name
        expect(task.target_host_host).to eq target_host_host
        expect(task.target_host_domains).to include target_host_domain
        expect(task.target_host_subdir).to eq target_host_subdir
        expect(task.target_host_parent_id).to eq site.id
        expect(task.source_site_id).to eq site.id
        expect(task.copy_contents).to include('pages')
        expect(task.copy_contents).to include('files')
        expect(task.copy_contents).to include('editor_templates')
        expect(task.copy_contents).to include('dictionaries')
        expect(task.copy_contents).to include('loop_settings')
        expect(task.copy_contents).to include('page_searches')
        expect(task.copy_contents).to include('source_cleaner_templates')
        expect(task.copy_contents).to include('theme_templates')
        expect(task.copy_contents).to include('translate_langs')
        expect(task.copy_contents).to include('translate_text_caches')
        expect(task.copy_contents).to include('word_dictionaries')
      end

      expect(enqueued_jobs.size).to eq 1
      enqueued_jobs.first.tap do |job|
        expect(job).to include(job: Sys::SiteCopyJob)
        expect(job).to include(args: [])
      end
    end
  end
end
