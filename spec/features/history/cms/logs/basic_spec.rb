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

      click_on I18n.t("ss.links.download")
      click_on I18n.t("ss.buttons.download")

      csv_source = SS::ChunkReader.new(page.html).to_a.join
      SS::Csv.open(StringIO.new(csv_source)) do |csv|
        table = csv.read
        expect(table.length).to eq 7
        expect(table.headers).to include(*csv_header)
        table[0].tap do |row|
          expect(row[History::Log.t(:created)]).to be_present
          expect(row[History::Log.t(:user_name)]).to eq "#{cms_user.name}(#{cms_user.id})"
          expect(row[History::Log.t(:model_name)]).to eq "class(1)"
          expect(row[History::Log.t(:action)]).to eq "create"
          expect(row[History::Log.t(:path)]).to start_with("/path/to/")
        end
      end

      visit index_path
      click_on I18n.t('ss.links.delete')
      click_on I18n.t('ss.buttons.delete')
      expect(page).to have_css('.list-item', count: 8)

      visit index_path
      click_on I18n.t('ss.links.delete')
      select I18n.t("history.options.duration.all_delete"), from: 'item[delete_term]'
      click_on I18n.t('ss.buttons.delete')
      expect(page).to have_css('.list-item', count: 1)
    end
  end
end
