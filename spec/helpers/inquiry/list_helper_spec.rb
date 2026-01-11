require 'spec_helper'

describe Inquiry::ListHelper, type: :helper, dbscope: :example do
  let(:site) { cms_site }

  let!(:node) do
    create :inquiry_node_node, cur_site: site, filename: 'inquiry', name: 'Inquiry'
  end
  let!(:form) do
    create :inquiry_node_form, cur_site: site, filename: 'inquiry/form1', name: 'Form1'
  end

  before do
    @cur_site = site
    @cur_node = node
    @items = [form]

    allow(node).to receive(:cur_date=)
    allow(node).to receive(:loop_format_shirasagi?).and_return(false)
  end

  describe '#render_inquiry_list' do
    it 'falls back from blank loop_setting html to loop_liquid' do
      loop_setting = instance_double('Cms::LoopSetting', html_format_liquid?: true, html: '')
      allow(node).to receive(:loop_setting).and_return(loop_setting)
      allow(node).to receive(:loop_liquid).and_return('Hello {{ nodes.size }}')

      expect(helper).to receive(:render_list_with_liquid) do |source, assigns|
        expect(source).to eq('Hello {{ nodes.size }}')
        expect(assigns['nodes']).to be_present
        'ok'
      end

      helper.render_inquiry_list
    end

    it 'ensures render_list_with_liquid receives a non-blank template' do
      loop_setting = instance_double('Cms::LoopSetting', html_format_liquid?: true, html: '')
      allow(node).to receive(:loop_setting).and_return(loop_setting)
      allow(node).to receive(:loop_liquid).and_return('')

      expect(helper).to receive(:render_list_with_liquid) do |source, _assigns|
        expect(source).to be_present
        'ok'
      end

      helper.render_inquiry_list
    end
  end
end
