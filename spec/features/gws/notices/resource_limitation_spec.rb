require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create(:gws_notice_folder) }
  let(:notice_name) { unique_id }
  let(:notice_text) { unique_id * rand(2..10) }
  let!(:notice_file) { tmp_ss_file(contents: '0123456789', user: gws_user) }

  before do
    login_gws_user
  end

  def create_notice
    visit gws_notice_main_path(site: site)
    click_on I18n.t('ss.navi.editable')
    expect(page).to have_css('.tree-navi', text: folder.name)
    first('.tree-navi', text: folder.name).click
    click_on I18n.t('ss.links.new')

    within 'form#item-form' do
      fill_in 'item[name]', with: notice_name
      fill_in 'item[text]', with: notice_text

      within '#addon-gws-agents-addons-file' do
        click_on I18n.t('ss.links.upload')
      end
    end
    wait_for_cbox do
      click_on notice_file.name
    end
    within 'form#item-form' do
      click_on I18n.t('ss.buttons.save')
    end
  end

  context 'when notice is created' do
    it do
      create_notice
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.notice_total_body_size).to eq notice_text.length
      expect(folder.notice_total_file_size).to eq notice_file.size
    end
  end

  context 'when resource limitation is reached' do
    before do
      folder.set(
        notice_total_body_size: folder.notice_total_body_size_limit - notice_text.length,
        notice_total_file_size: folder.notice_total_file_size_limit - notice_file.size
      )
    end

    it do
      create_notice
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.notice_total_body_size).to eq folder.notice_total_body_size_limit
      expect(folder.notice_total_file_size).to eq folder.notice_total_file_size_limit
    end
  end

  context 'when resource limitation is exceeded' do
    let(:exceeded_total_body_size_limit) do
      I18n.t(
        'mongoid.errors.models.gws/notice/post.exceeded_total_body_size_limit',
        size: folder.notice_total_body_size_limit.to_s(:human_size),
        limit: folder.notice_total_body_size_limit.to_s(:human_size)
      )
    end
    let(:exceeded_total_file_size_limit) do
      I18n.t(
        'mongoid.errors.models.gws/notice/post.exceeded_total_file_size_limit',
        size: folder.notice_total_body_size_limit.to_s(:human_size),
        limit: folder.notice_total_body_size_limit.to_s(:human_size)
      )
    end

    before do
      folder.set(
        notice_total_body_size: folder.notice_total_body_size_limit - notice_text.length + 1,
        notice_total_file_size: folder.notice_total_file_size_limit - notice_file.size + 1
      )
    end

    it do
      create_notice
      within '#errorExplanation' do
        expect(page).to have_content(exceeded_total_body_size_limit)
        expect(page).to have_content(exceeded_total_file_size_limit)
      end

      folder.reload
      expect(folder.notice_total_body_size).to eq folder.notice_total_body_size_limit - notice_text.length + 1
      expect(folder.notice_total_file_size).to eq folder.notice_total_file_size_limit - notice_file.size + 1
    end
  end
end
