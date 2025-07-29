require 'spec_helper'

describe "cms_agents_parts_page", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:layout) { create_cms_layout part }
  let!(:node) { create :cms_node, layout_id: layout.id }

  let(:item1) { create :cms_page }
  let(:item2) { create :cms_page }

  let(:now_time) { Time.zone.now }

  context "no cache" do
    let!(:part) do
      create :cms_part_page, upper_html: '<div class="parts">', lower_html: '</div>', ajax_view: "enabled"
    end

    it "#index" do
      expect(part.ajax_view_cache_enabled?).to be false

      Timecop.freeze(now_time) do
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be false

        item1
        visit node.full_url
        wait_for_all_ajax_parts
        expect(page).to have_css(".pages article")
        expect(page).to have_link(item1.name)
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be false

        item2
        visit node.full_url
        wait_for_all_ajax_parts
        expect(page).to have_css(".pages article")
        expect(page).to have_link(item1.name)
        expect(page).to have_link(item2.name)
      end

      Timecop.return
    end
  end

  context "with cache" do
    let!(:part) do
      create(:cms_part_page, upper_html: '<div class="parts">', lower_html: '</div>',
        ajax_view: "enabled", ajax_view_expire_seconds: 10)
    end

    after do
      Rails.cache.clear
    end

    it "#index" do
      expect(part.ajax_view_cache_enabled?).to be true

      Timecop.freeze(now_time) do
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be false

        item1
        visit node.full_url
        wait_for_all_ajax_parts
        expect(page).to have_css(".pages article")
        expect(page).to have_link(item1.name)
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be true

        item2
        visit node.full_url
        wait_for_all_ajax_parts
        expect(page).to have_css(".pages article")
        expect(page).to have_link(item1.name)
        expect(page).to have_no_link(item2.name)
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be true
      end

      Timecop.freeze(now_time + 5.seconds) do
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be true

        visit node.full_url
        wait_for_all_ajax_parts
        expect(page).to have_css(".pages article")
        expect(page).to have_link(item1.name)
        expect(page).to have_no_link(item2.name)
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be true
      end

      Timecop.freeze(now_time + 10.seconds) do
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be false

        visit node.full_url
        wait_for_all_ajax_parts
        expect(page).to have_css(".pages article")
        expect(page).to have_link(item1.name)
        expect(page).to have_link(item2.name)
        expect(Rails.cache.exist?(part.ajax_view_cache_key)).to be true
      end

      Timecop.return
    end
  end
end
