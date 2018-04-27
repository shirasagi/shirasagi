require 'spec_helper'

RSpec.describe Gws::Schedule::Todo, type: :model, dbscope: :example do
  describe "todo" do
    context "default params" do
      subject { create :gws_schedule_todo }
      it { expect(subject.errors.size).to eq 0 }
    end

    context "with reminders" do
      let(:reminder_condition) do
        { 'user_id' => gws_user.id, 'state' => 'mail', 'interval' => 10, 'interval_type' => 'minutes' }
      end
      subject { create :gws_schedule_todo, in_reminder_conditions: [ reminder_condition ] }
      it { expect(subject.errors.size).to eq 0 }
      it { expect(Gws::Reminder.where(item_id: subject.id, model: described_class.name.underscore).count).to eq 1 }
    end
  end
end
