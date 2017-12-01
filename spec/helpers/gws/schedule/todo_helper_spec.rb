require 'spec_helper'

describe Gws::Schedule::TodoHelper, type: :helper do

  let(:item) { create :gws_schedule_todo }

  before do
    helper.instance_variable_set :@cur_user, gws_user
    helper.instance_variable_set :@cur_site, gws_site
    helper.instance_variable_set :@model, Gws::Schedule::Todo
    helper.instance_variable_set :@item, item
  end

  describe "menu_items" do
    context "allowed" do
      it "index" do
        expect(helper.menu_items('index').count).to eq 1
      end

      it "new create lock" do
        %w(new create lock).each { |act| expect(helper.menu_items(act).count).to eq 1 }
      end

      it "edit update delete move" do
        %w(edit update delete move).each { |act| expect(helper.menu_items(act).count).to eq 2 }
      end

      it "other" do
        expect(helper.menu_items('other').count).to eq 5
      end
    end
  end
end
