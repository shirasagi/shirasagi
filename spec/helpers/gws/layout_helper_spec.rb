require 'spec_helper'

describe Gws::LayoutHelper, type: :helper, dbscope: :example do
  before do
    helper.instance_variable_set :@cur_user, gws_user
    helper.instance_variable_set :@cur_site, gws_site
  end

  describe "category_label_css" do
    let(:item) { create :gws_board_category, color: '#000000' }

    it do
      html = helper.category_label_css(item)
      expect(html).to eq "background-color: #000000; color: #ffffff;"
    end
  end
end
