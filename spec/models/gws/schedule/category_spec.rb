require 'spec_helper'

RSpec.describe Gws::Schedule::Category, type: :model, dbscope: :example do
  describe "category" do
    context "blank params" do
      subject { Gws::Schedule::Category.new.valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create :gws_schedule_category }
      it { expect(subject.errors.size).to eq 0 }
    end

    context "black" do
      subject { create :gws_schedule_category, color: "#000000" }

      it { expect(subject.errors.size).to eq 0 }
      it { expect(subject.color).to eq "#000000" }
      it { expect(subject.text_color).to eq "#ffffff" }
    end

    context "dark color" do
      subject { create :gws_schedule_category, color: "#777777" }

      it { expect(subject.errors.size).to eq 0 }
      it { expect(subject.color).to eq "#777777" }
      it { expect(subject.text_color).to eq "#ffffff" }
    end

    context "white" do
      subject { create :gws_schedule_category, color: "#ffffff" }

      it { expect(subject.errors.size).to eq 0 }
      it { expect(subject.color).to eq "#ffffff" }
      it { expect(subject.text_color).to eq "#000000" }
    end

    context "light color" do
      subject { create :gws_schedule_category, color: "#888888" }

      it { expect(subject.errors.size).to eq 0 }
      it { expect(subject.color).to eq "#888888" }
      it { expect(subject.text_color).to eq "#000000" }
    end
  end
end
