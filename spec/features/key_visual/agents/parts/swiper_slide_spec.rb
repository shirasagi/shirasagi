require 'spec_helper'

describe KeyVisual::Agents::Parts::SwiperSlideController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:folder_path) { unique_id }
  let!(:part) { create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", limit: limit }
  let!(:layout) { create_cms_layout part }
  let!(:node) { create :cms_node, layout: layout, filename: folder_path }
  let!(:item1) { create :key_visual_image, filename: "#{folder_path}/#{unique_id}", order: 1 }
  let!(:item2) { create :key_visual_image, filename: "#{folder_path}/#{unique_id}", order: 2 }
  let!(:item3) { create :key_visual_image, filename: "#{folder_path}/#{unique_id}", order: 3 }

  context "without limit" do
    let(:limit) { nil }

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item1.id}']")
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item2.id}']")
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item3.id}']")
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")

        if part.kv_navigation == "show"
          wait_event_to_fire("transitionEnd") do
            first(".ss-swiper-slide-button-next").click
          end
          expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item2.id}']")
          wait_event_to_fire("transitionEnd") do
            first(".ss-swiper-slide-button-prev").click
          end
          expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
        end

        if %w(disc number).include?(part.kv_pagination_style)
          wait_event_to_fire("transitionEnd") do
            first(".swiper-pagination-bullet[aria-label='Go to slide 3']").click
          end
          expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item3.id}']")
          wait_event_to_fire("transitionEnd") do
            first(".swiper-pagination-bullet[aria-label='Go to slide 1']").click
          end
          expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
        end

        if part.kv_thumbnail == "show"
          expect(page).to have_css(".ss-swiper-slide-thumbnail .swiper-slide-active")
        end

        if part.kv_autoplay == "enabled"
          wait_event_to_fire("autoplayStart") do
            click_on I18n.t('key_visual.controls.start')
          end
          expect(page).to have_css(".ss-swiper-slide-play[aria-pressed='true']")
          expect(page).to have_css(".ss-swiper-slide-stop[aria-pressed='false']")
        end

        if part.kv_autoplay != "disabled"
          wait_event_to_fire("autoplayStop") do
            click_on I18n.t('key_visual.controls.stop')
          end
          expect(page).to have_css(".ss-swiper-slide-play[aria-pressed='false']")
          expect(page).to have_css(".ss-swiper-slide-stop[aria-pressed='true']")
        end
      end
    end
  end

  context "with limit" do
    let(:limit) { 2 }

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        within ".ss-swiper-slide-main" do
          expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item1.id}']")
          expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item2.id}']")
          expect(page).to have_no_css(".ss-swiper-slide-item[data-ss-page-id='#{item3.id}']")
          expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
        end
      end
    end
  end
end
