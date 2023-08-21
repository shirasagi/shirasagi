require 'spec_helper'

describe Jmaxml::Action::SwitchUrgency, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    let!(:layout1) { create_cms_layout }
    subject { create(:jmaxml_action_switch_urgency, urgency_layout_id: layout1.id) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
  end

  describe '#execute' do
    let!(:layout1) { create_cms_layout }
    let!(:layout2) { create_cms_layout }
    let!(:index_page) { create :cms_page, layout_id: layout1.id, filename: "index.html" }
    let!(:urgency_node) { create :urgency_node_layout, urgency_default_layout_id: layout1.id }
    let(:node) { create(:rss_node_weather_xml) }
    let(:page) { create(:rss_weather_xml_page, cur_node: node) }
    let(:context) { OpenStruct.new(site: site, node: node) }
    subject { create(:jmaxml_action_switch_urgency, urgency_layout_id: layout2.id) }

    it do
      subject.execute(page, context)

      index_page.reload
      expect(index_page.layout_id).to eq layout2.id
    end
  end
end
