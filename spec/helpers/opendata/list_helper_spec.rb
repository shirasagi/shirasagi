require 'spec_helper'

describe Opendata::ListHelper, type: :helper, dbscope: :example do
  describe ".render_page_list" do
    context "without block" do
      subject { helper.render_page_list }

      before do
        @cur_site = cms_site
        create(:opendata_node_search_dataset)
        @cur_part = create(:opendata_part_dataset)
        @cur_node = create(:opendata_node_dataset)
        @cur_path = @cur_node.filename
        @item1 = create(:opendata_dataset, node: @cur_node)
        @item2 = create(:opendata_dataset, node: @cur_node)
        @item3 = create(:opendata_dataset, node: @cur_node)
        @items = Opendata::Dataset.all
      end

      it do
        is_expected.to include "<article class=\"item-#{@item1.basename.sub(/\..*/, "").dasherize} new \">"
        is_expected.to include "<article class=\"item-#{@item2.basename.sub(/\..*/, "").dasherize} new \">"
        is_expected.to include "<article class=\"item-#{@item3.basename.sub(/\..*/, "").dasherize} new \">"
      end
    end

    context "with block" do
      let(:now) { Time.zone.now }

      subject do
        helper.render_page_list { "現在の時刻は#{now}" }
      end

      before do
        @cur_site = cms_site
        create(:opendata_node_search_dataset)
        @cur_part = create(:opendata_part_dataset)
        @cur_node = create(:opendata_node_dataset)
        @cur_path = @cur_node.filename
        @item1 = create(:opendata_dataset, node: @cur_node)
        @item2 = create(:opendata_dataset, node: @cur_node)
        @item3 = create(:opendata_dataset, node: @cur_node)
        @items = Opendata::Dataset.all
      end

      it do
        is_expected.to include "現在の時刻は#{now}"
      end
    end
  end
end
