require 'spec_helper'

describe "facility_images", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:facility_node) { create :facility_node_node }
  let!(:node) { create :facility_node_page, cur_node: facility_node }
  let(:expected_addon_titles) { %w(メタ情報 公開予約 公開設定 写真情報 基本情報 施設写真 管理権限).sort }

  before { login_cms_user }

  context "basic crud" do
    let(:name) { unique_id }
    let(:order) { rand(1..10) }
    let(:image_alt) { unique_id }
    let(:image_comment) { Array.new(2) { unique_id } }
    let(:image_thumb_width) { SS::ImageConverter::DEFAULT_THUMB_WIDTH * 2 }
    let(:image_thumb_height) { SS::ImageConverter::DEFAULT_THUMB_HEIGHT * 2 }
    let(:name2) { unique_id }

    it do
      visit facility_images_path(site: site, cid: node)

      #
      # Create
      #
      click_on I18n.t("ss.links.new")
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[order]", with: order

        ss_upload_file "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg", addon: "#addon-facility-agents-addons-image_file"
        within "#addon-facility-agents-addons-image_file" do
          expect(page).to have_css(".file-view", text: "keyvisual.jpg")
        end

        fill_in "item[image_alt]", with: image_alt
        fill_in "item[image_comment]", with: image_comment.join("\n")
        fill_in "item[image_thumb_width]", with: image_thumb_width
        fill_in "item[image_thumb_height]", with: image_thumb_height

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      expect(Facility::Image.all.count).to eq 1
      image_page = Facility::Image.all.first
      expect(image_page.name).to eq name
      expect(image_page.order).to eq order
      expect(image_page.image).to be_present
      expect(image_page.image_alt).to eq image_alt
      expect(image_page.image_comment).to eq image_comment.join("\r\n")
      expect(image_page.image_thumb_width).to eq image_thumb_width
      expect(image_page.image_thumb_height).to eq image_thumb_height
      image = image_page.image
      expect(image.name).to eq "keyvisual.jpg"
      expect(image.filename).to eq "keyvisual.jpg"
      expect(image.size).to be > 0
      expect(image.owner_item_type).to eq image_page.class.name
      expect(image.owner_item_id).to eq image_page.id

      # add extra image
      image2 = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: "logo.png")
      image_page2 = create(:facility_image, cur_node: node, order: order + 10, image_id: image2.id, image_alt: unique_id)

      #
      # Check Facility::Node::Page
      #
      visit facility_pages_path(site: site, cid: facility_node)
      wait_for_all_turbo_frames
      within ".list-items" do
        click_on node.name
      end
      within "#facility-info" do
        expect(page).to have_css(".summary.image img[alt='#{image_page.image_alt}']")

        info = image_element_info(first(".summary.image img[alt='#{image_page.image_alt}']"))
        expect(info[:width]).to eq 140
        expect(info[:height]).to eq 41
      end
      within "#facility-images" do
        expect(page).to have_css("img[alt='#{image_page2.image_alt}']")

        info = image_element_info(first("img[alt='#{image_page2.image_alt}']"))
        expect(info[:width]).to eq 140
        expect(info[:height]).to eq 140
      end

      #
      # Edit
      #
      visit facility_images_path(site: site, cid: node)
      within ".list-items" do
        click_on name
      end
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      click_on I18n.t("ss.links.edit")
      wait_for_js_ready
      expect(page.all("form .addon-head h2").map(&:text).sort).to eq expected_addon_titles
      within "form#item-form" do
        fill_in "item[name]", with: name2

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      image_page.reload
      expect(image_page.name).to eq name2

      #
      # Delete
      #
      visit facility_images_path(site: site, cid: node)
      within ".list-items" do
        click_on name2
      end
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { image_page.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { image.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
