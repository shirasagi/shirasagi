require 'spec_helper'

describe 'sys_site_copy', type: :feature, dbscope: :example do
  let(:index_path) { sys_site_copy_path }

  context 'without login/auth' do
    it 'without login' do
      visit index_path
      expect(current_path).to eq sns_login_path
    end

    it 'without auth' do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end
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

        click_on 'サイトを選択する'
      end

      within 'table.sys-copy' do
        choose "radio-#{site.id}"
      end
      within 'div.sys-copy' do
        click_on 'サイトを設定する'
      end

      within '#item-form' do
        click_on '確認'
      end

      click_on '実行'

      expect(current_path).to eq index_path
      expect(page).to have_css('#notice .wrap', text: 'サイト複製を開始しました。')

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
