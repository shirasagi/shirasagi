require 'spec_helper'

describe Rss::WeatherXmlPage, dbscope: :example do
  let(:node) { create :rss_node_weather_xml }
  let(:item) { create :rss_weather_xml_page, cur_node: node }
  let(:show_path) { Rails.application.routes.url_helpers.rss_weather_xml_path(site: item.site, cid: node, id: item) }

  describe "#attributes" do
    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to be_nil }
    it { expect(item.path).not_to be_nil }
    it { expect(item.url).not_to be_nil }
    it { expect(item.full_url).not_to be_nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
  end

  describe "becomes_with_route" do
    it do
      page = Cms::Page.find(item.id).becomes_with_route
      expect(page).not_to be_nil
      expect(page.class).to eq Rss::WeatherXmlPage
      expect(page.changed?).to be_falsey
    end
  end
end
