require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  # let(:map_point1) do
  #   {
  #     "name" => unique_id, "loc" => [ rand(130..140), rand(30..40) ], "text" => "",
  #     "image" => "/assets/img/googlemaps/marker#{rand(0..9)}.png"
  #   }
  # end
  # let!(:page1) do
  #   create :article_page, cur_site: site, cur_node: node, map_reference_method: "direct", map_points: [ map_point1 ]
  # end

  let!(:form1) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:form1_column_select_page) do
    create(:cms_column_select_page, cur_site: site, cur_form: form1, node_ids: [ node.id ], required: "optional")
  end

  let!(:form2) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:form2_column_select_page) do
    create(:cms_column_select_page, cur_site: site, cur_form: form2, node_ids: [ node.id ], required: "optional")
  end

  let(:fetch_options_script) do
    <<~SCRIPT.freeze
      Array.from(
        document.querySelectorAll('#pseudo_map_reference_method option'),
        node => node.textContent.trim())
    SCRIPT
  end

  before do
    node.st_form_ids = [ form1.id, form2.id ]
    node.save!

    login_cms_user
  end

  describe "map reference" do
    it do
      visit new_article_page_path(site: site, cid: node)

      within 'form#item-form' do
        fill_in 'item[name]', with: unique_id

        #
        # フォームを変更すると、地図の指定方法の選択肢が変化するかどうかのチェック
        #
        ensure_addon_opened("#addon-map-agents-addons-page")
        within "#addon-map-agents-addons-page" do
          options = page.evaluate_script(fetch_options_script)
          expect(options.length).to eq 1
          expect(options).to include(I18n.t("map.options.map_reference_method.direct"))
        end

        wait_event_to_fire("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form1.name, from: 'in_form_id'
          end
        end

        ensure_addon_opened("#addon-map-agents-addons-page")
        within "#addon-map-agents-addons-page" do
          options = page.evaluate_script(fetch_options_script)
          expect(options.length).to eq 2
          expect(options).to include(I18n.t("map.options.map_reference_method.direct"), form1_column_select_page.name)
        end

        wait_event_to_fire("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form2.name, from: 'in_form_id'
          end
        end

        ensure_addon_opened("#addon-map-agents-addons-page")
        within "#addon-map-agents-addons-page" do
          options = page.evaluate_script(fetch_options_script)
          expect(options.length).to eq 2
          expect(options).to include(I18n.t("map.options.map_reference_method.direct"), form2_column_select_page.name)
        end

        wait_event_to_fire("ss:formDeactivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select I18n.t("cms.default_form"), from: 'in_form_id'
          end
        end

        ensure_addon_opened("#addon-map-agents-addons-page")
        within "#addon-map-agents-addons-page" do
          options = page.evaluate_script(fetch_options_script)
          expect(options.length).to eq 1
          expect(options).to include(I18n.t("map.options.map_reference_method.direct"))
        end

        #
        # 地図の指定方法が正しく保存されるかのチェック
        #
        wait_event_to_fire("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form1.name, from: 'in_form_id'
          end
        end
        ensure_addon_opened("#addon-map-agents-addons-page")
        within "#addon-map-agents-addons-page" do
          select form1_column_select_page.name, from: "pseudo_map_reference_method"
        end

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Article::Page.all.count).to eq 1
      Article::Page.all.site(site).first.tap do |item|
        expect(item.map_reference_method).to eq 'page'
        expect(item.map_reference_column_name).to eq form1_column_select_page.name
      end
    end
  end
end
