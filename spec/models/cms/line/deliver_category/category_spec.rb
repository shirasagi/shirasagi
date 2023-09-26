require 'spec_helper'

describe Cms::Line::DeliverCategory::Category, dbscope: :example do
  describe "validation" do
    it "basename valid" do
      basename = unique_id
      item = build(:cms_line_deliver_category_category, basename: basename)
      expect(item.valid?).to be_truthy
      expect(item.basename).to eq basename
      expect(item.filename).to eq basename
      expect(item.depth).to eq 1
    end

    it "basename invalid" do
      item = build(:cms_line_deliver_category_category, basename: "#{unique_id}/#{unique_id}")
      expect(item.valid?).to be_falsy
    end

    it "basename invalid" do
      item = build(:cms_line_deliver_category_category, basename: "#{unique_id}.html")
      expect(item.valid?).to be_falsy
    end
  end
end
