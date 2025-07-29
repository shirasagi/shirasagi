require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example do
  describe "history trash" do
    let!(:site) { gws_site }
    let(:user) { gws_user }
    let!(:site2) { cms_site }

    let(:start_on) { Date.new 2010, 1, 1 }
    let(:end_on) { Date.new 2010, 1, 1 }

    context "when destroy gws schedule plan" do
      let(:file) { tmp_ss_file(contents: '0123456789', site: site2, user: user) }
      subject { create :gws_schedule_plan, start_on: start_on, end_on: end_on, cur_site: site, cur_user: user }

      it do
        subject.file_ids = [ file.id ]
        subject.destroy
        expect(History::Trash.count).to eq 0
      end
    end
  end
end
