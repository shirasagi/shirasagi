require 'spec_helper'

describe "sys_image_resizes", type: :feature, dbscope: :example, js: true do
  describe "basic crud" do
    let(:state) { %w(enabled disabled).sample }
    let(:state_label) { I18n.t("ss.options.state.#{state}") }
    let(:max_width) { rand(601..700) }
    let(:max_height) { rand(601..700) }
    let(:size) { rand(1..5) }
    let(:quality) { rand(80..100) }
    let(:state2) { %w(enabled disabled).sample }
    let(:state2_label) { I18n.t("ss.options.state.#{state2}") }
    let(:max_width2) { rand(601..700) }
    let(:max_height2) { rand(601..700) }
    let(:size2) { rand(1..5) }
    let(:quality2) { rand(80..100) }

    it do
      expect(SS::ImageResize.all.count).to eq 0

      login_sys_user to: sys_image_resize_path
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        select state_label, from: "item[state]"
        fill_in "item[max_width]", with: max_width
        fill_in "item[max_height]", with: max_height
        fill_in "item[in_size_mb]", with: size
        fill_in "item[quality]", with: quality

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::ImageResize.all.count).to eq 1
      SS::ImageResize.all.first.tap do |image_resize|
        expect(image_resize.name).to be_blank
        expect(image_resize.order).to be_blank
        expect(image_resize.state).to eq state
        expect(image_resize.max_width).to eq max_width
        expect(image_resize.max_height).to eq max_height
        expect(image_resize.size).to eq size * 1_024 * 1_024
        expect(image_resize.quality).to eq quality
      end

      visit sys_image_resize_path
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        select state2_label, from: "item[state]"
        fill_in "item[max_width]", with: max_width2
        fill_in "item[max_height]", with: max_height2
        fill_in "item[in_size_mb]", with: size2
        fill_in "item[quality]", with: quality2

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::ImageResize.all.count).to eq 1
      SS::ImageResize.all.first.tap do |image_resize|
        expect(image_resize.name).to be_blank
        expect(image_resize.order).to be_blank
        expect(image_resize.state).to eq state2
        expect(image_resize.max_width).to eq max_width2
        expect(image_resize.max_height).to eq max_height2
        expect(image_resize.size).to eq size2 * 1_024 * 1_024
        expect(image_resize.quality).to eq quality2
      end
    end
  end
end
