require 'spec_helper'

describe "js_date_time_format", type: :feature, dbscope: :example, js: true, locale: :ja do
  describe ".convertDateTimeFormat" do
    let(:script) do
      <<~SCRIPT.freeze
        moment(arguments[0]).format(SS.convertDateTimeFormat(arguments[1]))
      SCRIPT
    end
    let(:now) { Time.zone.now.change(usec: 0) }

    it do
      visit sns_login_path

      '%Y-%1m-%1d (%a)'.tap do |format|
        val = page.evaluate_script(script, now.iso8601, format)
        # I18n.l localize '%a' but strftime doesn't
        expect(val).to eq I18n.l(now, format: format)
        expect(val).not_to eq now.strftime(format)
      end
      '%m月%d日 (%a)'.tap do |format|
        val = page.evaluate_script(script, now.iso8601, format)
        # I18n.l localize '%a' but strftime doesn't
        expect(val).to eq I18n.l(now, format: format)
        expect(val).not_to eq now.strftime(format)
      end
      '%Y/%1m/%1d %H:%M'.tap do |format|
        val = page.evaluate_script(script, now.iso8601, format)
        expect(val).to eq I18n.l(now, format: format)
        expect(val).to eq now.strftime(format)
      end
      '%Y-%m-%d %H:%M'.tap do |format|
        val = page.evaluate_script(script, now.iso8601, format)
        expect(val).to eq I18n.l(now, format: format)
        expect(val).to eq now.strftime(format)
      end
      '%Y年%1m月%1d日 %H時%M分'.tap do |format|
        val = page.evaluate_script(script, now.iso8601, format)
        expect(val).to eq I18n.l(now, format: format)
        expect(val).to eq now.strftime(format)
      end
      '%y/%m/%d %H:%M'.tap do |format|
        val = page.evaluate_script(script, now.iso8601, format)
        expect(val).to eq I18n.l(now, format: format)
        expect(val).to eq now.strftime(format)
      end
      '%Y/%m/%d %H:%M'.tap do |format|
        val = page.evaluate_script(script, now.iso8601, format)
        expect(val).to eq I18n.l(now, format: format)
        expect(val).to eq now.strftime(format)
      end
    end
  end

  describe ".formatTime" do
    let(:script) do
      <<~SCRIPT.freeze
        SS.formatTime(arguments[0], arguments[1])
      SCRIPT
    end
    let(:time) { "2019-07-09T14:33:38+0900" }

    it do
      visit sns_login_path

      val = page.evaluate_script(script, time)
      expect(val).to eq I18n.l(time.in_time_zone)

      "default".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone, format: format.to_sym)
      end
      "long".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone, format: format.to_sym)
      end
      "short".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone, format: format.to_sym)
      end
      "picker".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone, format: format.to_sym)
      end
      "gws_long".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone, format: format.to_sym)
      end
      # custom format
      "%Y/%m/%d %H:%M".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone, format: format)
      end
    end
  end

  describe ".formatDate" do
    let(:script) do
      <<~SCRIPT.freeze
        SS.formatDate(arguments[0], arguments[1])
      SCRIPT
    end
    let(:time) { "2019-07-09T14:33:38+0900" }

    it do
      visit sns_login_path

      val = page.evaluate_script(script, time)
      expect(val).to eq I18n.l(time.in_time_zone.to_date)

      "default".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone.to_date, format: format.to_sym)
      end
      "long".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone.to_date, format: format.to_sym)
      end
      "short".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone.to_date, format: format.to_sym)
      end
      "picker".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone.to_date, format: format.to_sym)
      end
      "gws_long".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone.to_date, format: format.to_sym)
      end
      # custom format
      "%Y/%m/%d".tap do |format|
        val = page.evaluate_script(script, time, format)
        expect(val).to eq I18n.l(time.in_time_zone, format: format)
      end
    end
  end
end
