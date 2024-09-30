require 'spec_helper'

describe Gws::NotifySetting, type: :model, dbscope: :example do
  context "default state" do
    it do
      expect(SS.config.gws.notify_setting).to eq nil

      expect(Gws::Schedule::Plan.default_notify_state).to eq "disabled"
      expect(Gws::Schedule::Plan.new.notify_state).to eq "disabled"

      expect(Gws::Schedule::Todo.default_notify_state).to eq "disabled"
      expect(Gws::Schedule::Todo.new.notify_state).to eq "disabled"

      expect(Gws::Schedule::Todo.default_notify_state).to eq "disabled"
      expect(Gws::Schedule::Todo.new.notify_state).to eq "disabled"

      expect(Gws::Board::Topic.default_notify_state).to eq "disabled"
      expect(Gws::Board::Topic.new.notify_state).to eq "disabled"
    end
  end

  context "enabled models given" do
    let(:notify_enabled_models) { %w(Gws::Schedule::Plan Gws::Schedule::Todo) }

    before do
      @save_config = SS.config.gws.notify_setting
      SS.config.replace_value_at(:gws, "notify_setting", "notify_enabled_models" => notify_enabled_models)
    end

    after do
      SS.config.replace_value_at(:gws, 'memo', @save_config)
    end

    it do
      expect(SS.config.gws.notify_setting["notify_enabled_models"]).to eq notify_enabled_models

      expect(Gws::Schedule::Plan.default_notify_state).to eq "enabled"
      expect(Gws::Schedule::Plan.new.notify_state).to eq "enabled"

      expect(Gws::Schedule::Todo.default_notify_state).to eq "enabled"
      expect(Gws::Schedule::Todo.new.notify_state).to eq "enabled"

      expect(Gws::Schedule::Todo.default_notify_state).to eq "enabled"
      expect(Gws::Schedule::Todo.new.notify_state).to eq "enabled"

      expect(Gws::Board::Topic.default_notify_state).to eq "disabled"
      expect(Gws::Board::Topic.new.notify_state).to eq "disabled"
    end
  end
end
