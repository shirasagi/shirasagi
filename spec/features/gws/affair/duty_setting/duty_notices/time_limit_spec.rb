require 'spec_helper'

describe "gws_affair_duty_notices", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let(:site) { gws_site }

    let(:day0830) { Time.zone.parse("2020/8/30") } #平日
    let(:day0831) { Time.zone.parse("2020/8/31") } #平日
    let(:day0901) { Time.zone.parse("2020/9/1") } #平日
    let(:now) { day0831.change(hour: 8, min: 30) }

    #context "basic crud" do
    #  it "#index" do
    #    login_user(user)
    #    visit gws_affair_attendance_main_path(site)
    #  end
    #end
  end
end
