require 'spec_helper'

describe "ads_part_banners", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :ads_node_banner, cur_site: site }

  context "basic crud with shirasagi format" do
    let(:name1) { "name-#{unique_id}" }
    let(:basename1) { "filename-#{unique_id}" }
    let(:upper_html1) do
      <<~HTML
        <div class="upper">#{unique_id}</div>
      HTML
    end
    let(:loop_html1) do
      <<~HTML
        <div class="loop">#{unique_id}</div>
      HTML
    end
    let(:lower_html1) do
      <<~HTML
        <div class="lower">#{unique_id}</div>
      HTML
    end

    let(:name2) { "name-#{unique_id}" }
    let(:basename2) { "filename-#{unique_id}" }
    let(:upper_html2) do
      <<~HTML
        <div class="upper">#{unique_id}</div>
      HTML
    end
    let(:loop_html2) do
      <<~HTML
        <div class="loop">#{unique_id}</div>
      HTML
    end
    let(:lower_html2) do
      <<~HTML
        <div class="lower">#{unique_id}</div>
      HTML
    end

    it do
      login_user user, to: node_parts_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_js_ready
      within "#addon-basic" do
        wait_for_cbox_opened { click_on I18n.t("ss.links.change") }
      end

      within_cbox do
        # クリックすると画面が遷移するので wait_for_cbox_closed は無用
        click_on I18n.t("cms.parts.ads/banner")
      end

      expect(page).to have_css("#addon-basic", text: I18n.t("cms.parts.ads/banner"))
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: name1
        fill_in "item[basename]", with: basename1

        select I18n.t("cms.options.loop_format.shirasagi"), from: "item[loop_format]"
        fill_in_code_mirror "item[upper_html]", with: upper_html1
        fill_in_code_mirror "item[loop_html]", with: loop_html1
        fill_in_code_mirror "item[lower_html]", with: lower_html1

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Ads::Part::Banner.all.count).to eq 1
      part = Ads::Part::Banner.all.first
      expect(part.site_id).to eq site.id
      expect(part.name).to eq name1
      expect(part.filename).to eq "#{node.filename}/#{basename1}.part.html"
      expect(part.loop_format).to eq "shirasagi"
      expect(part.upper_html.strip).to eq upper_html1.strip
      expect(part.loop_html.strip).to eq loop_html1.strip
      expect(part.lower_html.strip).to eq lower_html1.strip

      visit node_parts_path(site: site, cid: node)
      click_on part.name
      wait_for_js_ready
      click_on I18n.t("ss.links.edit")
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: name2
        fill_in "item[basename]", with: basename2

        fill_in_code_mirror "item[upper_html]", with: upper_html2
        fill_in_code_mirror "item[loop_html]", with: loop_html2
        fill_in_code_mirror "item[lower_html]", with: lower_html2

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Ads::Part::Banner.all.count).to eq 1
      part = Ads::Part::Banner.all.first
      expect(part.site_id).to eq site.id
      expect(part.name).to eq name2
      expect(part.filename).to eq "#{node.filename}/#{basename2}.part.html"
      expect(part.loop_format).to eq "shirasagi"
      expect(part.upper_html.strip).to eq upper_html2.strip
      expect(part.loop_html.strip).to eq loop_html2.strip
      expect(part.lower_html.strip).to eq lower_html2.strip

      visit node_parts_path(site: site, cid: node)
      click_on part.name
      wait_for_js_ready
      click_on I18n.t("ss.links.delete")
      wait_for_js_ready
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Ads::Part::Banner.all.count).to eq 0
      expect { part.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "basic crud with liquid format" do
    let(:name1) { "name-#{unique_id}" }
    let(:basename1) { "filename-#{unique_id}" }
    let(:loop_liquid1) do
      <<~HTML
        <div class="loop">#{unique_id}</div>
      HTML
    end

    let(:name2) { "name-#{unique_id}" }
    let(:basename2) { "filename-#{unique_id}" }
    let(:loop_liquid2) do
      <<~HTML
        <div class="loop">#{unique_id}</div>
      HTML
    end

    it do
      login_user user, to: node_parts_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_js_ready
      within "#addon-basic" do
        wait_for_cbox_opened { click_on I18n.t("ss.links.change") }
      end

      within_cbox do
        # クリックすると画面が遷移するので wait_for_cbox_closed は無用
        click_on I18n.t("cms.parts.ads/banner")
      end

      expect(page).to have_css("#addon-basic", text: I18n.t("cms.parts.ads/banner"))
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: name1
        fill_in "item[basename]", with: basename1

        select I18n.t("cms.options.loop_format.liquid"), from: "item[loop_format]"
        fill_in_code_mirror "item[loop_liquid]", with: loop_liquid1

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Ads::Part::Banner.all.count).to eq 1
      part = Ads::Part::Banner.all.first
      expect(part.site_id).to eq site.id
      expect(part.name).to eq name1
      expect(part.filename).to eq "#{node.filename}/#{basename1}.part.html"
      expect(part.loop_format).to eq "liquid"
      expect(part.loop_liquid.strip).to eq loop_liquid1.strip

      visit node_parts_path(site: site, cid: node)
      click_on part.name
      wait_for_js_ready
      click_on I18n.t("ss.links.edit")
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: name2
        fill_in "item[basename]", with: basename2

        fill_in_code_mirror "item[loop_liquid]", with: loop_liquid2

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Ads::Part::Banner.all.count).to eq 1
      part = Ads::Part::Banner.all.first
      expect(part.site_id).to eq site.id
      expect(part.name).to eq name2
      expect(part.filename).to eq "#{node.filename}/#{basename2}.part.html"
      expect(part.loop_format).to eq "liquid"
      expect(part.loop_liquid.strip).to eq loop_liquid2.strip

      visit node_parts_path(site: site, cid: node)
      click_on part.name
      wait_for_js_ready
      click_on I18n.t("ss.links.delete")
      wait_for_js_ready
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Ads::Part::Banner.all.count).to eq 0
      expect { part.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
