require 'spec_helper'

describe "article_node_map_search", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:article_node) { create(:article_node_page, cur_site: site) }

  context "basic crud" do
    let(:state1) { %w(enabled disabled).sample }
    let(:state_label1) { I18n.t("ss.options.state.#{state1}") }
    let(:max_width1) { rand(300..600) }
    let(:max_height1) { rand(300..600) }
    let(:size1) { rand(1..5) }
    let(:quality1) { rand(80..100) }
    let(:state2) { %w(enabled disabled).sample }
    let(:state_label2) { I18n.t("ss.options.state.#{state2}") }
    let(:max_width2) { rand(600..900) }
    let(:max_height2) { rand(600..900) }
    let(:size2) { rand(1..5) }
    let(:quality2) { rand(80..100) }

    context "when SS.config.ss.quality_option['type'] is disabled" do
      before do
        quality_option = @save_ss_quality_option = SS.config.ss.quality_option.dup
        quality_option['type'] = 'disabled'
        SS.config.replace_value_at(:ss, :quality_option, quality_option)
      end

      after do
        SS.config.replace_value_at(:ss, :quality_option, @save_ss_quality_option)
      end

      it do
        login_user user, to: article_pages_path(site: site, cid: article_node)
        # wait_for_all_turbo_frames
        click_on I18n.t("cms.node_config")
        within "#addon-cms-agents-addons-image_resize_setting" do
          click_on I18n.t("cms.add_image_resize")
        end

        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          select state_label1, from: "item[state]"
          fill_in "item[max_width]", with: max_width1
          fill_in "item[max_height]", with: max_height1

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Cms::ImageResize.all.count).to eq 1
        Cms::ImageResize.all.first.tap do |item|
          expect(item.site_id).to eq site.id
          expect(item.node_id).to eq article_node.id
          expect(item.state).to eq state1
          expect(item.max_width).to eq max_width1
          expect(item.max_height).to eq max_height1
          expect(item.size).to be_blank
          expect(item.quality).to be_blank
        end

        visit article_pages_path(site: site, cid: article_node)
        click_on I18n.t("cms.node_config")
        within "#addon-cms-agents-addons-image_resize_setting" do
          expect(page).to have_content(state_label1)
          expect(page).to have_content(max_width1)
          expect(page).to have_content(max_height1)

          click_on I18n.t("cms.add_image_resize")
        end

        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          select state_label2, from: "item[state]"
          fill_in "item[max_width]", with: max_width2
          fill_in "item[max_height]", with: max_height2

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Cms::ImageResize.all.count).to eq 1
        Cms::ImageResize.all.first.tap do |item|
          expect(item.site_id).to eq site.id
          expect(item.node_id).to eq article_node.id
          expect(item.state).to eq state2
          expect(item.max_width).to eq max_width2
          expect(item.max_height).to eq max_height2
          expect(item.size).to be_blank
          expect(item.quality).to be_blank
        end

        visit article_pages_path(site: site, cid: article_node)
        click_on I18n.t("cms.node_config")
        within "#addon-cms-agents-addons-image_resize_setting" do
          expect(page).to have_content(state_label2)
          expect(page).to have_content(max_width2)
          expect(page).to have_content(max_height2)

          click_on I18n.t("cms.add_image_resize")
        end

        page.accept_confirm(I18n.t("ss.confirm.delete")) do
          click_on I18n.t("ss.links.delete")
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        expect(Cms::ImageResize.all.count).to eq 0
      end
    end

    context "when SS.config.ss.quality_option['type'] is custom" do
      before do
        quality_option = @save_ss_quality_option = SS.config.ss.quality_option.dup
        quality_option['type'] = 'custom'
        SS.config.replace_value_at(:ss, :quality_option, quality_option)
      end

      after do
        SS.config.replace_value_at(:ss, :quality_option, @save_ss_quality_option)
      end

      it do
        login_user user, to: article_pages_path(site: site, cid: article_node)
        # wait_for_all_turbo_frames
        click_on I18n.t("cms.node_config")
        within "#addon-cms-agents-addons-image_resize_setting" do
          click_on I18n.t("cms.add_image_resize")
        end

        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          select state_label1, from: "item[state]"
          fill_in "item[max_width]", with: max_width1
          fill_in "item[max_height]", with: max_height1
          fill_in "item[in_size_mb]", with: size1
          fill_in "item[quality]", with: quality1

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Cms::ImageResize.all.count).to eq 1
        Cms::ImageResize.all.first.tap do |item|
          expect(item.site_id).to eq site.id
          expect(item.node_id).to eq article_node.id
          expect(item.state).to eq state1
          expect(item.max_width).to eq max_width1
          expect(item.max_height).to eq max_height1
          expect(item.size).to eq size1 * 1_024 * 1_024
          expect(item.quality).to eq quality1
        end

        visit article_pages_path(site: site, cid: article_node)
        click_on I18n.t("cms.node_config")
        within "#addon-cms-agents-addons-image_resize_setting" do
          expect(page).to have_content(state_label1)
          expect(page).to have_content(max_width1)
          expect(page).to have_content(max_height1)

          click_on I18n.t("cms.add_image_resize")
        end

        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          select state_label2, from: "item[state]"
          fill_in "item[max_width]", with: max_width2
          fill_in "item[max_height]", with: max_height2
          fill_in "item[in_size_mb]", with: size2
          fill_in "item[quality]", with: quality2

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Cms::ImageResize.all.count).to eq 1
        Cms::ImageResize.all.first.tap do |item|
          expect(item.site_id).to eq site.id
          expect(item.node_id).to eq article_node.id
          expect(item.state).to eq state2
          expect(item.max_width).to eq max_width2
          expect(item.max_height).to eq max_height2
          expect(item.size).to eq size2 * 1_024 * 1_024
          expect(item.quality).to eq quality2
        end

        visit article_pages_path(site: site, cid: article_node)
        click_on I18n.t("cms.node_config")
        within "#addon-cms-agents-addons-image_resize_setting" do
          expect(page).to have_content(state_label2)
          expect(page).to have_content(max_width2)
          expect(page).to have_content(max_height2)

          click_on I18n.t("cms.add_image_resize")
        end

        page.accept_confirm(I18n.t("ss.confirm.delete")) do
          click_on I18n.t("ss.links.delete")
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        expect(Cms::ImageResize.all.count).to eq 0
      end
    end
  end
end
