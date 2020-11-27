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

    before do
      login_sys_user
    end

    it do
      visit index_path

      within '#item-form' do
        fill_in 'item[target_host_name]', with: target_host_name
        fill_in 'item[target_host_host]', with: target_host_host
        fill_in 'item[target_host_domains]', with: target_host_domain

        check 'item_copy_contents_pages'
        check 'item_copy_contents_files'
        check 'item_copy_contents_editor_templates'
        check 'item_copy_contents_dictionaries'

        click_on I18n.t("sys.apis.sites.index")
      end

      within 'table.sys-copy' do
        click_on site.name
      end

      within '#item-form' do
        expect(page).to have_css(".ajax-selected", text: site.name)
        click_on I18n.t("ss.buttons.confirm")
      end

      click_on I18n.t("ss.buttons.run")

      expect(current_path).to eq index_path
      expect(page).to have_css('#notice .wrap', text: I18n.t("sys.site_copy/started_job"), wait: 60)

      expect(Sys::SiteCopyTask.count).to eq 1
      Sys::SiteCopyTask.first.tap do |task|
        expect(task.target_host_name).to eq target_host_name
        expect(task.target_host_host).to eq target_host_host
        expect(task.target_host_domains).to include target_host_domain
        expect(task.source_site_id).to eq site.id
        expect(task.copy_contents).to include('pages')
        expect(task.copy_contents).to include('files')
        expect(task.copy_contents).to include('editor_templates')
        expect(task.copy_contents).to include('dictionaries')
      end

      expect(enqueued_jobs.size).to eq 1
      enqueued_jobs.first.tap do |job|
        expect(job).to include(job: Sys::SiteCopyJob)
        expect(job).to include(args: [])
      end
    end
  end
end
