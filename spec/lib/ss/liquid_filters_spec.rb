require 'spec_helper'

describe SS::LiquidFilters do
  let(:assigns) { { "value" => value } }
  let(:template) { Liquid::Template.parse(source) }
  subject { template.render(assigns).to_s }

  describe "ss_date" do
    let(:value) { Time.zone.now }

    context "without arguments" do
      let(:source) { "{{ value || ss_date }}" }
      it { is_expected.to eq I18n.l(value.to_date) }
    end

    context "with 'default'" do
      let(:source) { "{{ value || ss_date: 'default' }}" }
      it { is_expected.to eq I18n.l(value.to_date, format: :default) }
    end

    context "with 'iso'" do
      let(:source) { "{{ value || ss_date: 'iso' }}" }
      it { is_expected.to eq I18n.l(value.to_date, format: :iso) }
    end

    context "with 'long'" do
      let(:source) { "{{ value || ss_date: 'long' }}" }
      it { is_expected.to eq I18n.l(value.to_date, format: :long) }
    end

    context "with 'short'" do
      let(:source) { "{{ value || ss_date: 'short' }}" }
      it { is_expected.to eq I18n.l(value.to_date, format: :short) }
    end

    context "with custom date format" do
      let(:source) { "{{ value || ss_date: '%Y/%m' }}" }
      it { is_expected.to eq value.to_date.strftime('%Y/%m') }
    end
  end

  describe "ss_time" do
    let(:value) { Time.zone.now }

    context "without arguments" do
      let(:source) { "{{ value || ss_time }}" }
      it { is_expected.to eq I18n.l(value) }
    end

    context "with 'default'" do
      let(:source) { "{{ value || ss_time: 'default' }}" }
      it { is_expected.to eq I18n.l(value, format: :default) }
    end

    context "with 'iso'" do
      let(:source) { "{{ value || ss_time: 'iso' }}" }
      it { is_expected.to eq I18n.l(value, format: :iso) }
    end

    context "with 'long'" do
      let(:source) { "{{ value || ss_time: 'long' }}" }
      it { is_expected.to eq I18n.l(value, format: :long) }
    end

    context "with 'short'" do
      let(:source) { "{{ value || ss_time: 'short' }}" }
      it { is_expected.to eq I18n.l(value, format: :short) }
    end

    context "with custom date format" do
      let(:source) { "{{ value || ss_time: '%F %j' }}" }
      it { is_expected.to eq value.strftime('%F %j') }
    end
  end

  describe "delimited" do
    let(:source) { "{{ value || delimited }}" }

    context "with 0" do
      let(:value) { 0 }
      it { is_expected.to eq "0" }
    end

    context "with 1" do
      let(:value) { 1 }
      it { is_expected.to eq "1" }
    end

    context "with -1" do
      let(:value) { -1 }
      it { is_expected.to eq "-1" }
    end

    context "with 2756" do
      let(:value) { 2_756 }
      it { is_expected.to eq "2,756" }
    end

    context "with - 2756" do
      let(:value) { -2_756 }
      it { is_expected.to eq "-2,756" }
    end
  end

  describe "human_size" do
    let(:source) { "{{ value || human_size }}" }

    context "with 0" do
      let(:value) { 0 }
      it { is_expected.to eq "0#{I18n.t("number.human.storage_units.units.byte")}" }
    end

    context "with 10" do
      let(:value) { 10 }
      it { is_expected.to eq "10#{I18n.t("number.human.storage_units.units.byte")}" }
    end

    context "with 10k" do
      let(:value) { 10 * 1_024 }
      it { is_expected.to eq "10KB" }
    end

    context "with 10M" do
      let(:value) { 10 * 1_024 * 1_024 }
      it { is_expected.to eq "10MB" }
    end

    context "with -10" do
      let(:value) { -10 }
      it { is_expected.to eq "-10#{I18n.t("number.human.storage_units.units.byte")}" }
    end

    context "with -10M" do
      let(:value) { - 10 * 1_024 * 1_024 }
      it { is_expected.to eq "-10485760バイト" }
    end
  end

  describe "ss_append" do
    let(:value) { unique_id }
    let(:appendee) { unique_id }
    let(:source) { "{{ value || ss_append: \"#{appendee}\"}}" }

    it { is_expected.to eq "#{value}#{appendee}" }
  end

  describe "ss_prepend" do
    let(:value) { unique_id }
    let(:prepend) { unique_id }
    let(:source) { "{{ value || ss_prepend: \"#{prepend}\"}}" }

    it { is_expected.to eq "#{prepend}#{value}" }
  end

  describe "ss_img_src" do
    let(:prepend) { unique_id }
    let(:source) { "{{ value || ss_img_src}}" }

    context "with blank" do
      let(:value) { "" }
      it { is_expected.to eq "" }
    end

    context "with <img>" do
      let(:value) { "<img src=\"/profile.png\">" }
      it { is_expected.to eq "/profile.png" }
    end

    context "with 2 <img>" do
      let(:value) { "<img src=\"/one.png\"><img src=\"/two.png\">" }
      it { is_expected.to eq "/one.png" }
    end
  end

  describe "expand_path" do
    let(:path) { "http://www.example.jp/" }
    let(:source) { "{{ value || expand_path: \"#{path}\"}}" }

    context "with blank" do
      let(:value) { "" }
      it { is_expected.to eq "" }
    end

    context "with relative path" do
      let(:value) { "img/cover.png" }
      it { is_expected.to eq "http://www.example.jp/img/cover.png" }
    end

    context "with absolute path" do
      let(:value) { "/img/cover.png" }
      it { is_expected.to eq "http://www.example.jp/img/cover.png" }
    end
  end

  describe "sanitize" do
    let(:source) { "{{ value || sanitize }}" }

    context "with blank" do
      let(:value) { "" }
      it { is_expected.to eq "" }
    end

    context "with some safe tags" do
      let(:value) { "<a href=\"/profile\"><img src=\"/profile.png\"></a>" }
      it { is_expected.to eq value }
    end

    context "with <script> which is unsafe" do
      let(:value) { "<script>alert('hello')</script>" }
      it { is_expected.to eq "alert('hello')" }
    end
  end
end
