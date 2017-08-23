require 'spec_helper'

RSpec.describe Gws::Schedule::Todo, type: :model do

  describe "todo" do
    context "default params" do
      subject { create :gws_schedule_todo }
      it { expect(subject.errors.size).to eq 0 }
      it { expect(Gws::Reminder.where(item_id: subject.id, model: described_class.name.underscore).count).to eq 1 }
    end
  end
end
