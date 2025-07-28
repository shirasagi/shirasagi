require 'spec_helper'

describe Cms::Line::DeliverCategory::Selection, dbscope: :example do
  let!(:category) { create :cms_line_deliver_category_category, basename: unique_id }

  describe "validation" do
    it "basename valid" do
      basename = unique_id
      item = build(:cms_line_deliver_category_selection, parent: category, basename: basename)
      expect(item.valid?).to be_truthy
      expect(item.basename).to eq basename
      expect(item.filename).to eq "#{category.filename}/#{basename}"
      expect(item.depth).to eq 2
    end

    it "basename invalid" do
      item = build(:cms_line_deliver_category_selection, basename: "#{unique_id}/#{unique_id}")
      expect(item.valid?).to be_falsy
    end

    it "basename invalid" do
      item = build(:cms_line_deliver_category_selection, basename: "#{unique_id}.html")
      expect(item.valid?).to be_falsy
    end
  end

  describe "rename category" do
    let!(:basename1) { unique_id }
    let!(:basename2) { unique_id }
    let!(:selection) { create :cms_line_deliver_category_selection, parent: category, basename: basename2 }

    it do
      category.basename = basename1
      category.update
      expect(category.errors).to be_blank

      category.reload
      selection.reload
      expect(category.basename).to eq basename1
      expect(category.filename).to eq basename1
      expect(selection.basename).to eq basename2
      expect(selection.filename).to eq "#{basename1}/#{basename2}"
    end
  end

  describe "destroy category" do
    let!(:selection) { create :cms_line_deliver_category_selection, parent: category, basename: unique_id }

    it do
      expect(Cms::Line::DeliverCategory::Base.all.count).to eq 2
      category.destroy
      expect(Cms::Line::DeliverCategory::Base.all.count).to eq 0
    end
  end
end
