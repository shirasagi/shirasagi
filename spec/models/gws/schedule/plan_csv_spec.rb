require 'spec_helper'

RSpec.describe Gws::Schedule::PlanCsv::Exporter, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  describe ".to_csv" do
    context "too long text should be truncated" do
      let!(:item) do
        create(
          :gws_schedule_plan, cur_site: site, cur_user: user, allday: 'allday',
          start_on: start_on, end_on: end_on, text: text)
      end
      let(:start_on) { Date.new 2010, 1, 1 }
      let(:end_on) { Date.new 2010, 1, 1 }
      let(:text) { unique_id * 500 }
      let(:opts) { { user: user, site: site, truncate: true } }

      it do
        criteria = Gws::Schedule::Plan.all
        described_class.enum_csv(criteria, opts).tap do |enum|
          source = enum.to_a.join.encode
          SS::Csv.open(StringIO.new(source)) do |csv|
            table = csv.read
            expect(table.headers).to include(*%i[id name allday text].map { Gws::Schedule::Plan.t(_1) })
            expect(table.length).to eq 1
            table[0].tap do |row|
              text = row[Gws::Schedule::Plan.t(:text)]
              expect(text).to end_with("...")
              expect(text).to have(1_024).characters
            end
          end
        end
      end
    end

    context "too many groups should be truncated" do
      let!(:item) do
        create(
          :gws_schedule_plan, cur_site: site, cur_user: user, allday: 'allday', start_on: start_on, end_on: end_on,
          member_group_ids: group_ids, readable_group_ids: group_ids, group_ids: group_ids)
      end
      let(:start_on) { Date.new 2010, 1, 1 }
      let(:end_on) { Date.new 2010, 1, 1 }
      let(:group_ids) do
        Array.new(30) { create(:gws_group, name: "#{site.name}/#{unique_id}").then { _1.id } }
      end
      let(:opts) { { user: user, site: site, truncate: true } }

      it do
        criteria = Gws::Schedule::Plan.all
        described_class.enum_csv(criteria, opts).tap do |enum|
          source = enum.to_a.join.encode
          SS::Csv.open(StringIO.new(source)) do |csv|
            table = csv.read
            expect(table.headers).to include(*%i[id name allday group_ids].map { Gws::Schedule::Plan.t(_1) })
            expect(table.length).to eq 1
            table[0].tap do |row|
              row[Gws::Schedule::Plan.t(:member_group_ids)].tap do |group_names|
                group_names = group_names.split(/\R/)
                expect(group_names).to end_with(I18n.t("ss.overflow_group", count: 20))
                expect(group_names).to have(11).items
              end
              row[Gws::Schedule::Plan.t(:readable_group_ids)].tap do |group_names|
                group_names = group_names.split(/\R/)
                expect(group_names).to end_with(I18n.t("ss.overflow_group", count: 20))
                expect(group_names).to have(11).items
              end
              row[Gws::Schedule::Plan.t(:group_ids)].tap do |group_names|
                group_names = group_names.split(/\R/)
                expect(group_names).to end_with(I18n.t("ss.overflow_group", count: 20))
                expect(group_names).to have(11).items
              end
            end
          end
        end
      end
    end
  end
end
