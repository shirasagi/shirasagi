require 'spec_helper'

describe Article::Page, dbscope: :example do
  describe "validation" do
    let(:site_limit0) { create :cms_site_unique, max_name_length: 0 }
    let(:site_limit80) { create :cms_site_unique, max_name_length: 80 }

    it "basename" do
      item = build(:article_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end

    it "name with limit 0" do
      item = build(:article_page_10_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:article_page_100_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:article_page_1000_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy
    end

    it "name with limit 80" do
      item = build(:article_page_10_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_truthy

      item = build(:article_page_100_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey

      item = build(:article_page_1000_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey
    end
  end
end
