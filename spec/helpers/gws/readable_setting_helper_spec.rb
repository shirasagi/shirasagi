require 'spec_helper'

describe Gws::ReadableSettingHelper, type: :helper, dbscope: :example do
  let!(:group1) { create :gws_group, name: "#{gws_site.name}/#{unique_id}" }

  before do
    helper.instance_variable_set :@cur_user, gws_user
    helper.instance_variable_set :@cur_site, gws_site
    helper.instance_variable_set :@cur_group, group1
  end

  describe "intepret_readable_setting_config" do
    let(:group_ids) { Array.new(rand(1..3)) { rand(1..100) } }
    let(:user_ids) { Array.new(rand(1..3)) { rand(1..100) } }
    let(:custom_group_ids) { Array.new(rand(1..3)) { rand(1..100) } }
    subject do
      { "setting_range" => "select", "group_ids" => group_ids, "user_ids" => user_ids, "custom_group_ids" => custom_group_ids }
    end

    context "when setting_range is select" do
      it do
        setting = helper.intepret_readable_setting_config(subject)
        expect(setting[:setting_range]).to eq "select"
        expect(setting[:group_ids]).to eq group_ids
        expect(setting[:user_ids]).to eq user_ids
        expect(setting[:custom_group_ids]).to eq custom_group_ids
      end
    end

    context "when setting_range is public" do
      before do
        subject["setting_range"] = "public"
      end

      it do
        setting = helper.intepret_readable_setting_config(subject)
        expect(setting[:setting_range]).to eq "public"
        expect(setting[:group_ids]).to be_blank
        expect(setting[:user_ids]).to be_blank
        expect(setting[:custom_group_ids]).to be_blank
      end
    end

    context "when setting_range is private" do
      before do
        subject["setting_range"] = "private"
      end

      it do
        setting = helper.intepret_readable_setting_config(subject)
        expect(setting[:setting_range]).to eq "private"
        expect(setting[:group_ids]).to be_blank
        expect(setting[:user_ids]).to be_blank
        expect(setting[:custom_group_ids]).to be_blank
      end
    end

    context "when setting_range is unknown" do
      before do
        subject["setting_range"] = "unknown-setting-range-#{unique_id}"
      end

      it do
        setting = helper.intepret_readable_setting_config(subject)
        expect(setting).to be_nil
      end
    end

    context "when id is string" do
      before do
        subject["group_ids"] = group_ids.map(&:to_s)
        subject["user_ids"] = user_ids.map(&:to_s)
        subject["custom_group_ids"] = custom_group_ids.map(&:to_s)
      end

      it do
        setting = helper.intepret_readable_setting_config(subject)
        expect(setting[:setting_range]).to eq "select"
        expect(setting[:group_ids]).to eq group_ids
        expect(setting[:user_ids]).to eq user_ids
        expect(setting[:custom_group_ids]).to eq custom_group_ids
      end
    end

    context "when cur_group is given as group_ids" do
      before do
        subject["group_ids"] = %w(cur_group)
      end

      it do
        setting = helper.intepret_readable_setting_config(subject)
        expect(setting[:setting_range]).to eq "select"
        expect(setting[:group_ids]).to eq [ group1.id ]
      end
    end

    context "when cur_site is given as group_ids" do
      before do
        subject["group_ids"] = %w(cur_site)
      end

      it do
        setting = helper.intepret_readable_setting_config(subject)
        expect(setting[:setting_range]).to eq "select"
        expect(setting[:group_ids]).to eq [ gws_site.id ]
      end
    end

    context "when cur_user is given as user_ids" do
      before do
        subject["user_ids"] = %w(cur_user)
      end

      it do
        setting = helper.intepret_readable_setting_config(subject)
        expect(setting[:setting_range]).to eq "select"
        expect(setting[:user_ids]).to eq [ gws_user.id ]
      end
    end

    context "when nil is given" do
      before do
        subject["user_ids"] = %w(cur_user)
      end

      it do
        setting = helper.intepret_readable_setting_config(nil)
        expect(setting).to be_nil
      end
    end

    context "when empty hash is given" do
      before do
        subject["user_ids"] = %w(cur_user)
      end

      it do
        setting = helper.intepret_readable_setting_config({})
        expect(setting).to be_nil
      end
    end
  end
end
