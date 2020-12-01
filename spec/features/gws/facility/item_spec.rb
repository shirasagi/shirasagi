require 'spec_helper'

describe "facility_item", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:index_path) { gws_facility_items_path site.id }
  let(:import_path) { import_gws_facility_items_path site.id }
  let(:download_path) { download_gws_facility_items_path site.id }
  let!(:category){ create(:gws_facility_category, name: "会議室") }
  let!(:admin){ create(:gws_user)}

  before { login_gws_user }

  describe "#import" do
    before { visit import_path }
    context "when the all datas on csv is valid" do
      it "the datas are imported" do

        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/facility/gws_items_1.csv"
          expect{ click_button I18n.t('ss.links.import') }.to change{ Gws::Facility::Item.count }.from(0).to(2)
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        item1 = Gws::Facility::Item.site(site).where(name: "example1").first
        item2 = Gws::Facility::Item.site(site).where(name: "example2").first

        expect(item1).to be_valid
        expect(item1.category.name).to eq "会議室"
        expect(item1.order).to eq 1
        expect(item1.approval_check_state).to eq "enabled"
        expect(item1.columns.first._type).to eq "Gws::Column::TextField"
        expect(item1.columns.first.name).to eq "column_example"
        expect(item1.columns.first.required).to eq "required"
        expect(item1.columns.first.prefix_label).to eq nil
        expect(item1.columns.first.postfix_label).to eq nil
        expect(item1.columns.first.input_type).to eq "email"
        expect(item1.columns.first.place_holder).to eq "Mail"
        expect(item1.readable_setting_range).to eq "select"
        expect(item1.readable_group_names).to eq %w(シラサギ市/企画政策部)
        expect(item1.readable_member_names).to eq ["gw-admin (admin)"]
        expect(item1.group_names).to eq %w(シラサギ市/企画政策部/政策課)
        expect(item1.user_names).to eq ["gw-admin (admin)"]
        expect(item1.permission_level).to eq 1

        expect(item2).to be_valid
        expect(item2.category.name).to eq "会議室"
        expect(item2.order).to eq 2
        expect(item2.approval_check_state).to eq "disabled"
        expect(item2.columns.first._type).to eq "Gws::Column::NumberField"
        expect(item2.columns.first.name).to eq "column_example2"
        expect(item2.columns.first.required).to eq "optional"
        expect(item2.columns.first.prefix_label).to eq "pre"
        expect(item2.columns.first.postfix_label).to eq "post"
        expect(item2.columns.first.min_decimal.to_i).to eq 0
        expect(item2.columns.first.max_decimal.to_i).to eq 5
        expect(item2.columns.first.initial_decimal.to_i).to eq 1
        expect(item2.columns.first.scale.to_i).to eq 2
        expect(item2.columns.first.minus_type).to eq "normal"
        expect(item2.columns.first.place_holder).to eq nil
        expect(item2.readable_setting_range).to eq "select"
        expect(item2.readable_group_names).to eq %w(シラサギ市/企画政策部)
        expect(item2.readable_member_names).to eq ["gw-admin (admin)"]
        expect(item2.group_names).to eq %w(シラサギ市/企画政策部/政策課)
        expect(item2.user_names).to eq ["gw-admin (admin)"]
        expect(item2.permission_level).to eq 2
      end
    end

    context "when some data on csv is invalid" do
      it "does not import the only data in CSVfile" do
        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/facility/gws_items_2.csv"
          click_button I18n.t('ss.links.import')
        end
        expect(status_code).to eq 200
        expect(current_path).to eq import_path
        items = Gws::Facility::Item.site(site)
        expect(items.size).to eq 1
        normal_item = Gws::Facility::Item.site(site).find_by(name: "normal")
        expect(items).to include normal_item
        expect(items.map(&:approval_check_state)).not_to include "disabled"
      end
    end
  end

  describe "#download" do
    before do
      create(
        :gws_facility_item, name: "test", category: category,
        approval_check_state: "disabled", order: 3, readable_setting_range: "public",
        site: site, user: user
      )
      visit index_path
    end
    let(:time){ Time.zone.now }
    it "downloads CSVfile" do
      Timecop.freeze(time) do
        within "nav.nav-menu" do
          click_link I18n.t('ss.links.download')
        end
        expect(status_code).to eq 200
        expect(page.response_headers['Content-Type']).to eq("text/csv")
        expect(page.response_headers['Content-Disposition']).to eq("attachment; filename*=UTF-8''gws_items_#{time.to_i}.csv")
      end

      csv = CSV.parse(page.html.encode("UTF-8", "SJIS"), headers: true)
      expect(csv.headers.include?(I18n.t("gws/facility/item.csv.id"))).to be_truthy
      expect(csv.headers.include?(I18n.t("gws/facility/item.csv.name"))).to be_truthy
      expect(csv.headers.include?(I18n.t("gws/facility/item.csv.category_id"))).to be_truthy
    end
  end
end
