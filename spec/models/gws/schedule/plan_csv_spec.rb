require 'spec_helper'

RSpec.describe Gws::Schedule::PlanCsv, type: :model, dbscope: :example do
  let!(:item) { create :gws_schedule_plan, allday: 'allday', start_on: start_on, end_on: end_on }
  let(:start_on) { Date.new 2010, 1, 1 }
  let(:end_on) { Date.new 2010, 1, 1 }
  let(:opts) { { user: gws_user, site: gws_site } }

  describe "plan" do
    context "export" do
      let(:described_class) { Gws::Schedule::PlanCsv::Exporter }

      it do
        criteria = Gws::Schedule::Plan.all
        expect(described_class.to_csv(criteria, opts).present?).to be_truthy
      end
    end
  end
end
