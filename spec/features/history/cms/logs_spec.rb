require 'spec_helper'

describe "history_cms_logs" do
  subject(:site) { cms_site }
  subject(:index_path) { history_cms_logs_path site.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before do
      login_cms_user

      create(:history_log, site_id: cms_site.id, user_id: cms_user.id, url: "/path/to/#{unique_id}")
      create(:history_log, site_id: cms_site.id, user_id: cms_user.id, url: "/path/to/#{unique_id}")
      create(:history_log, site_id: cms_site.id, user_id: cms_user.id, url: "/path/to/#{unique_id}")
      create(:history_log, site_id: cms_site.id, user_id: cms_user.id, url: "/path/to/#{unique_id}")
      create(:history_log, site_id: cms_site.id, user_id: cms_user.id, url: "/path/to/#{unique_id}")
    end

    it "#index" do
      visit index_path
      expect(current_path).to eq index_path
      expect(page).to have_css('.list-item', count: 5)

      click_on 'ダウンロード'
      click_on 'ダウンロード'

      expect(page).to have_content('Date,User,Target,Action,URL')
      expect(page).to have_content(',create,/path/to/')

      visit index_path
      click_on '削除する'
      click_on '削除'
      expect(page).to have_css('.list-item', count: 6)

      visit index_path
      click_on '削除する'
      select 'すべて削除', from: 'item[save_term]'
      click_on '削除'
      expect(page).to have_css('.list-item', count: 1)
    end
  end
end
