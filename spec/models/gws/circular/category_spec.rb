require 'spec_helper'

RSpec.describe Gws::Circular::Category, type: :model, dbscope: :example do
  let(:site) { gws_site }

  context "when parent category is not existed" do
    it do
      item = described_class.create(cur_site: site, name: "#{unique_id}/#{unique_id}")
      expect(item).to be_invalid
      expect(item.errors[:base].length).to eq 1
      expect(item.errors[:base]).to include(I18n.t("mongoid.errors.models.gws/circular/category.not_found_parent"))
    end
  end

  context "when category which has children is deleting" do
    it do
      parent = described_class.create(cur_site: site, name: unique_id)
      child = described_class.create(cur_site: site, name: "#{parent.name}/#{unique_id}")
      expect(parent).to be_valid
      expect(child).to be_valid

      parent.destroy
      expect(parent.errors[:base].length).to eq 1
      expect(parent.errors[:base]).to include(I18n.t("mongoid.errors.models.gws/circular/category.found_children"))
    end
  end

  context "when category depth is too deep" do
    it do
      parent = described_class.create(cur_site: site, name: unique_id)
      child = described_class.create(cur_site: site, name: "#{parent.name}/#{unique_id}")
      expect(parent).to be_valid
      expect(child).to be_valid

      grand_child = described_class.create(cur_site: site, name: "#{child.name}/#{unique_id}")
      expect(grand_child).to be_invalid
      expect(grand_child.errors[:name].length).to eq 1
      expect(grand_child.errors[:name]).to include(I18n.t("mongoid.errors.models.gws/circular/category.too_deep", max: 2))
    end
  end
end
