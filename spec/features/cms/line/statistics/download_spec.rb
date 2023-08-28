require 'spec_helper'

describe "cms/line/statistic", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:message1) { create :cms_line_message }
  let(:message2) { create :cms_line_message }
  let(:item1) { create :cms_line_multicast_statistic, name: message1.name, message: message1 }
  let(:item2) { create :cms_line_multicast_statistic, name: message2.name, message: message2 }
  let(:index_path) { cms_line_statistics_path site }

  describe "basic crud" do
    before { login_cms_user }

    context "multicast case" do
      it "#download" do
        item1
        item2
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
