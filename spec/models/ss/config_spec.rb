require 'spec_helper'

describe SS::Config do
  describe ".env" do
    it { expect(SS.config.env.storage).not_to be_nil }
  end

  describe ".method_missing" do
    it { expect(SS.config.cms.serve_static_pages).not_to be_nil }

    it "not to raise NoMethodError" do
      method_name = "method_#{unique_id}".to_sym
      expect { SS.config.send(method_name) }.not_to raise_error
    end
  end

  describe ".respond_to?" do
    it do
      expect(SS.config.respond_to?("cms")).to be_truthy
      expect(SS.config.respond_to?(:cms)).to be_truthy
      expect(SS.config.respond_to?("cms-#{unique_id}")).to be_falsey
    end
  end

  describe ".load_config" do
    let!(:base_dir) { tmpdir }
    let!(:config_name) { unique_id }
    let!(:default_config) do
      ::FileUtils.mkdir_p("#{base_dir}/defaults")
      config_path = "#{base_dir}/defaults/#{config_name}.yml"
      ::File.open(config_path, "wt") do |f|
        f.puts "production: &production"
        f.puts "  hello: world"
        f.puts ""
        f.puts "test:"
        f.puts "  <<: *production"
        f.puts ""
        f.puts "development:"
        f.puts "  <<: *production"
      end
      config_path
    end
    subject! { described_class.new(base_dir) }

    context "only default" do
      let(:config_path) { "#{base_dir}/defaults/#{config_name}.yml" }

      it do
        expect(subject.respond_to?(config_name)).to be_truthy
        expect(subject.send(config_name).hello).to eq "world"
      end
    end

    # ckan フォルダーやパーツを無効化できるようにするため、設定の defaults が定義されていなくても設定を読み込められるようにする
    # see: https://shirasagi.github.io/features/disable_route.html
    context "without default" do
      let(:config_path) { "#{base_dir}/#{config_name}.yml" }

      it do
        expect(subject.respond_to?(config_name)).to be_truthy
        expect(subject.send(config_name).hello).to eq "world"
      end
    end
  end
end
