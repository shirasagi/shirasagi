require 'spec_helper'

describe KeyVisual::Agents::Parts::SwiperSlideController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:folder_path) { unique_id }
  let!(:layout) { create_cms_layout part }
  let!(:node) { create :member_node_photo, layout: layout, filename: folder_path }
  let!(:item1) { create :member_photo, filename: "#{folder_path}/#{unique_id}", order: 1 }
  let!(:item2) { create :member_photo, filename: "#{folder_path}/#{unique_id}", order: 2 }
  let!(:item3) { create :member_photo, filename: "#{folder_path}/#{unique_id}", order: 3, slideable_state: "closed" }
  let!(:item4) { create :member_photo, filename: "#{folder_path}/#{unique_id}", order: 4, state: "closed" }

  context "without limit" do
    let!(:part) do
      create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", limit: nil, kv_thumbnail: "show"
    end

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item1.id}']")
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item2.id}']")
        expect(page).to have_no_css(".ss-swiper-slide-item[data-ss-page-id='#{item3.id}']")
        expect(page).to have_no_css(".ss-swiper-slide-item[data-ss-page-id='#{item4.id}']")

        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
      end
    end
  end
end
