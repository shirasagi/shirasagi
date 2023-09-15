require 'spec_helper'

describe KeyVisual::Agents::Parts::SwiperSlideController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:folder_path) { unique_id }
  let!(:layout) { create_cms_layout part }
  let!(:node) { create :cms_node, layout: layout, filename: folder_path }
  let!(:item1) { create :key_visual_image, filename: "#{folder_path}/#{unique_id}", order: 1 }
  let!(:item2) { create :key_visual_image, filename: "#{folder_path}/#{unique_id}", order: 2 }
  let!(:item3) { create :key_visual_image, filename: "#{folder_path}/#{unique_id}", order: 3 }

  context "without limit" do
    let!(:part) { create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", limit: nil }

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item1.id}']")
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item2.id}']")
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item3.id}']")

        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
      end
    end
  end

  context "with limit" do
    let!(:part) { create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", limit: 2 }

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        within ".ss-swiper-slide-main" do
          expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item1.id}']")
          expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item2.id}']")
          expect(page).to have_no_css(".ss-swiper-slide-item[data-ss-page-id='#{item3.id}']")

          # wait for slider initialization
          expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
        end
      end
    end
  end

  context "when kv_navigation is set to 'show'" do
    let!(:part) { create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", kv_navigation: "show" }

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")

        wait_for_event_fired("swipertransitionend") do
          first(".ss-swiper-slide-button-next").click
        end
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item2.id}']")
        wait_for_event_fired("swipertransitionend") do
          first(".ss-swiper-slide-button-prev").click
        end
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
      end
    end
  end

  context "when kv_pagination_style is set to 'disc' or 'number'" do
    let!(:part) do
      create(
        :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", kv_pagination_style: %w(disc number).sample
      )
    end

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")

        wait_for_event_fired("swipertransitionend") do
          aria_label = I18n.t("ss.swiper_slide.pagination_bullet_message").sub("{{index}}", "3")
          first(".swiper-pagination-bullet[aria-label='#{aria_label}']").click
        end
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item3.id}']")
        wait_for_event_fired("swipertransitionend") do
          aria_label = I18n.t("ss.swiper_slide.pagination_bullet_message").sub("{{index}}", "1")
          first(".swiper-pagination-bullet[aria-label='#{aria_label}']").click
        end
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
      end
    end
  end

  context "when kv_thumbnail is set to 'show'" do
    let!(:part) { create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", kv_thumbnail: "show" }

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")

        expect(page).to have_css(".ss-swiper-slide-thumbnail .swiper-slide-active")
      end
    end
  end

  context "when kv_autoplay is set to 'enabled'" do
    let!(:part) { create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", kv_autoplay: "enabled" }

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")

        wait_for_event_fired("swiperautoplaystart") do
          click_on I18n.t('key_visual.controls.start')
        end
        expect(page).to have_css(".ss-swiper-slide-play[aria-pressed='true']")
        expect(page).to have_css(".ss-swiper-slide-stop[aria-pressed='false']")
      end
    end
  end

  context "when kv_autoplay is set to 'started'" do
    let!(:part) { create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", kv_autoplay: "started" }

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")

        wait_for_event_fired("swiperautoplaystop") do
          click_on I18n.t('key_visual.controls.stop')
        end
        expect(page).to have_css(".ss-swiper-slide-play[aria-pressed='false']")
        expect(page).to have_css(".ss-swiper-slide-stop[aria-pressed='true']")
      end
    end

    context "when display remark" do
      let!(:part) { create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}" }

      before do
        item1.remark = unique_id
        item1.display_remark = %w(remark)
        item1.update

        item2.remark = unique_id
        item2.display_remark = %w(title)
        item2.update
      end

      it do
        visit node.full_url

        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
        within ".swiper-slide-active[data-ss-page-id='#{item1.id}']" do
          within ".slide-remark" do
            expect(page).to have_no_css(".title", text: item1.name)
            expect(page).to have_css(".remark", text: item1.remark)
          end
        end

        wait_event_to_fire("transitionEnd") do
          first(".swiper-pagination-bullet[aria-label='Go to slide 2']").click
        end
        within ".swiper-slide-active[data-ss-page-id='#{item2.id}']" do
          within ".slide-remark" do
            expect(page).to have_css(".title", text: item2.name)
            expect(page).to have_no_css(".remark", text: item2.remark)
          end
        end

        wait_event_to_fire("transitionEnd") do
          first(".swiper-pagination-bullet[aria-label='Go to slide 3']").click
        end
        within ".swiper-slide-active[data-ss-page-id='#{item3.id}']" do
          expect(page).to have_no_css(".slide-remark")
        end
      end
    end
  end
end
