require 'spec_helper'

describe KeyVisual::Agents::Parts::SwiperSlideController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:folder_path) { unique_id }
  let!(:layout) { create_cms_layout part }
  let!(:node) { create :cms_node_page, layout: layout, filename: folder_path }
  let!(:item1) do
    thumb = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site)
    create :cms_page, filename: "#{folder_path}/#{unique_id}", order: 1, thumb: thumb
  end
  let!(:item2) do
    thumb = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site)
    create :article_page, filename: "#{folder_path}/#{unique_id}", order: 2, thumb: thumb
  end
  let!(:item3) do
    thumb = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site)
    create :facility_notice, filename: "#{folder_path}/#{unique_id}", order: 3, thumb: thumb
  end
  let!(:item4) do
    # closed page
    thumb = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site)
    create :cms_page, filename: "#{folder_path}/#{unique_id}", order: 4, state: "closed", thumb: thumb
  end
  # no thumb
  let!(:item5) { create :cms_page, filename: "#{folder_path}/#{unique_id}", order: 5, thumb: nil }

  context "without limit" do
    let!(:part) do
      create :key_visual_part_swiper_slide, filename: "#{folder_path}/#{unique_id}", limit: nil, kv_thumbnail: "show"
    end

    it do
      visit node.full_url

      within ".ss-swiper-slide#key_visual-swiper_slide-#{part.id}" do
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item1.id}']")
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item2.id}']")
        expect(page).to have_css(".ss-swiper-slide-item[data-ss-page-id='#{item3.id}']")
        expect(page).to have_no_css(".ss-swiper-slide-item[data-ss-page-id='#{item4.id}']")
        expect(page).to have_no_css(".ss-swiper-slide-item[data-ss-page-id='#{item5.id}']")

        # wait for slider initialization
        expect(page).to have_css(".swiper-slide-active[data-ss-page-id='#{item1.id}']")
      end
    end
  end
end
