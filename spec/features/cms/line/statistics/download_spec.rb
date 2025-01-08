require 'spec_helper'

describe "cms/line/statistic", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { cms_site }
  let!(:message1) { create :cms_line_message, cur_site: site }
  let!(:message2) { create :cms_line_message, cur_site: site }
  let!(:item1) do
    Timecop.freeze(now - 5.minutes) do
      create :cms_line_multicast_statistic, cur_site: site, name: message1.name, message: message1
    end
  end
  let!(:item2) do
    Timecop.freeze(now - 4.minutes) do
      create :cms_line_multicast_statistic, cur_site: site, name: message2.name, message: message2
    end
  end
  let(:index_path) { cms_line_statistics_path site }

  describe "basic crud" do
    before { login_cms_user }

    context "multicast case" do
      it "#download" do
        visit index_path
        click_on I18n.t("ss.buttons.download")

        wait_for_download
        csv = ::CSV.read(downloads.first, headers: true, encoding: 'UTF-8')
        expect(csv.length).to eq 2

        expect(csv[0][0]).to eq item2.name
        expect(csv[1][0]).to eq item1.name
      end
    end
  end
end
