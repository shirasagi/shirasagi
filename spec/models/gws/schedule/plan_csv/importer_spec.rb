require 'spec_helper'

RSpec.describe Gws::Schedule::PlanCsv::Importer, type: :model, dbscope: :example do
  let(:in_file) { Fs::UploadedFile.create_from_file "#{Rails.root}/spec/fixtures/gws/schedule/gws_schedule_plans_1.csv" }

  describe "plan" do
    context "with empty" do
      subject { described_class.new }
      its(:valid?) { is_expected.to be_falsey }
    end

    context "with valid item" do
      subject { described_class.new(in_file: in_file, cur_site: gws_site, cur_user: gws_user) }
      its(:valid?) { is_expected.to be_truthy }
      it do
        expect(subject.import(confirm: true)).to be_truthy
        subject.import
        expect(Gws::Schedule::Plan.count).to eq 20
      end
    end
  end
end
