require 'spec_helper'

RSpec.describe Gws::Tabular do
  describe ".render_component" do
    it "ActionView のレンダリング注釈（BEGIN/END）を除去する" do
      annotated = <<~HTML
        <!-- BEGIN app/components/gws/tabular/column/text_field_component/show_text.html.erb -->
        20260108テスト
        <!-- END app/components/gws/tabular/column/text_field_component/show_text.html.erb -->
      HTML

      allow_any_instance_of(ApplicationController).to receive(:render_to_string).and_return(annotated)

      result = described_class.render_component(Object.new)
      expect(result).to eq "20260108テスト"
    end
  end
end
