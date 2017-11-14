require 'spec_helper'
require 'timecop'

describe Gws::Schedule::TodoJob, dbscope: :example do
  let(:site) {gws_site}
  let(:user) {gws_user}
  let(:started) {Time.zone.now}

  describe '.perform_later' do
    before do
      1.upto(12*3) do |i|
        Timecop.travel(started.ago(i.month)) do
          create(:gws_schedule_todo)
        end
      end
    end

    context 'default removed two years ago' do
      before do
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(Gws::Schedule::Todo.count).to eq 23
      end
    end

    context 'delete one year ago' do
      before do
        site.todo_delete_threshold = 1
        site.save!
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(Gws::Schedule::Todo.count).to eq 11
      end
    end
  end
end