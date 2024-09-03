require 'spec_helper'

describe "gws_workflow2_form_externals", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  context "basic crud" do
    let(:name) { "name-#{unique_id}" }
    let(:name2) { "name-#{unique_id}" }
    let(:order) { rand(10..20) }
    let(:url) { "/#{unique_id}/" }
    let(:description) { Array.new(2) { "description-#{unique_id}" } }
    let(:memo) { Array.new(2) { "memo-#{unique_id}" } }
    let(:state) { %w(public closed).sample }
    let(:state_label) { I18n.t("ss.options.state.#{state}") }
    let!(:cate) { create :gws_workflow2_form_category, cur_site: site }

    it do
      #
      # Create
      #
      visit gws_workflow2_form_externals_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[order]", with: order
        fill_in "item[url]", with: url
        fill_in "item[description]", with: description.join("\n")
        fill_in "item[memo]", with: memo.join("\n")
        select state_label, from: "item[state]"

        wait_for_cbox_opened { click_on I18n.t("gws.apis.categories.index") }
      end
      within_cbox do
        wait_for_cbox_closed { click_on cate.name }
      end
      within "form#item-form" do
        expect(page).to have_css("#addon-gws-agents-addons-workflow2-form_category", text: cate.name)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Form::Base.all.count).to eq 1
      Gws::Workflow2::Form::Base.all.first.tap do |item|
        expect(item).to be_a(Gws::Workflow2::Form::External)
        expect(item.site_id).to eq site.id
        expect(item.name).to eq name
        expect(item.description).to eq description.join("\r\n")
        expect(item.name).to eq name
        expect(item.description).to eq description.join("\r\n")
        expect(item.order).to eq order
        expect(item.url).to eq url
        expect(item.memo).to eq memo.join("\r\n")
        expect(item.state).to eq state
        expect(item.category_ids).to eq [ cate.id ]
      end

      #
      # Update
      #
      visit gws_workflow2_form_externals_path(site: site)
      click_on name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Form::Base.all.count).to eq 1
      Gws::Workflow2::Form::Base.all.first.tap do |item|
        expect(item).to be_a(Gws::Workflow2::Form::External)
        expect(item.name).to eq name2
      end

      #
      # Delete
      #
      visit gws_workflow2_form_externals_path(site: site)
      click_on name2
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Workflow2::Form::Base.all.count).to eq 0
    end
  end
end
