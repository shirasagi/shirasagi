require 'spec_helper'

describe "history_cms_logs", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { history_cms_logs_path site.id }
  let(:csv_header) do
    %i[created user_name model_name action path session_id request_id].map { |k| History::Log.t(k) }
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
      expect(page).to have_css('.list-item', count: 6)

      click_on 'ダウンロード'
      click_on 'ダウンロード'

      csv = ::SS::ChunkReader.new(page.html).to_a.join
      csv = csv.encode("UTF-8", "SJIS")
      csv = ::CSV.parse(csv, headers: true)

      expect(csv.length).to eq 6
      expect(csv.headers).to include(*csv_header)
      csv[0].tap do |row|
        expect(row[History::Log.t(:created)]).to be_present
        expect(row[History::Log.t(:user_name)]).to eq "#{cms_user.name}(#{cms_user.id})"
        expect(row[History::Log.t(:model_name)]).to eq "class(1)"
        expect(row[History::Log.t(:action)]).to eq "create"
        expect(row[History::Log.t(:path)]).to start_with("/path/to/")
      end

      visit index_path
      click_on I18n.t('ss.links.delete')
      click_on I18n.t('ss.buttons.delete')
      expect(page).to have_css('.list-item', count: 7)

      visit index_path
      click_on I18n.t('ss.links.delete')
      select I18n.t("history.save_term.all_delete"), from: 'item[delete_term]'
      click_on I18n.t('ss.buttons.delete')
      expect(page).to have_css('.list-item', count: 1)
    end
  end
end
