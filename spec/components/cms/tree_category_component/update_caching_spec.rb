require 'spec_helper'

describe Cms::TreeCategoryComponent, type: :component, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:cate) { create :category_node_node, site: site, filename: "c1", name: "c1" }

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  def new_component
    categories = Category::Node::Base.site(site)
    readable_categories = categories.readable(user, site: site)
    options = { readable_categories: readable_categories }
    described_class.new(site, categories, options)
  end

  context "create category" do
    let(:new_cate) { create :category_node_node }

    it do
      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present

      new_cate

      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{new_cate.id}\"]")).to be_present

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{new_cate.id}\"]")).to be_present
    end
  end

  context "update category" do
    let(:name) { unique_id }

    it do
      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.text).to include(cate.name)

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.text).to include(cate.name)

      Timecop.travel(1.day.ago) do
        cate.name = name
        cate.update!
        cate.reload
      end

      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.text).to include(name)

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.text).to include(name)
    end
  end

  context "destroy category" do
    it do
      cate_id = cate.id

      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate_id}\"]")).to be_present

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate_id}\"]")).to be_present

      cate.destroy

      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate_id}\"]")).to be_blank

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate_id}\"]")).to be_blank
    end
  end

  context "change redable categories" do
    let!(:user2) do
      create(:cms_user, name: unique_id, group_ids: cms_user.group_ids,
        cms_role_ids: cms_user.cms_role_ids)
    end

    it do
      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present

      cate.without_record_timestamps do
        cate.readable_setting_range = "select"
        cate.readable_member_ids = [user.id]
        cate.save!
      end

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present
    end

    it do
      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present

      cate.without_record_timestamps do
        cate.readable_setting_range = "select"
        cate.readable_member_ids = [user2.id]
        cate.save!
      end

      component = new_component
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".unreadable input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present

      component = new_component
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".unreadable input[name=\"item[category_ids][]\"][value=\"#{cate.id}\"]")).to be_present
    end
  end
end
