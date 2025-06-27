require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example do
  describe "#reminder_url" do
    let(:item) { create :gws_schedule_plan }
    subject { item.reminder_url }

    it do
      expect(subject).to be_a(Array)
      expect(subject.length).to eq 2
      expect(subject[0]).to eq "gws_schedule_plan_path"
      expect(subject[1]).to be_a(Hash)

      path = Rails.application.routes.url_helpers.send(subject[0], subject[1])
      expect(path).to eq "/.g#{item.site_id}/schedule/plans/#{item.id}"
    end
  end
end
