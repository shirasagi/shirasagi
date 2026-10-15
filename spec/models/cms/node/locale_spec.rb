require 'spec_helper'

describe Cms::Node, type: :model, dbscope: :example do
  context "must be defined its name under mongoid.models" do
    it do
      models = Mongoid.models.select { _1.include?(Cms::Model::Node) }
      models.reject! { _1.name.end_with?("Base") }
      expect(models).to have_at_least(100).items

      models.sort_by { _1.name }.each do |m|
        key = m.model_name.i18n_key
        expect(I18n.t(key, scope: "mongoid.models", default: nil)).to be_present, "#{key} が mongoid.models に未定義です。"
      end
    end
  end

  context "name under cms.nodes is obsoleted" do
    it do
      expect(I18n.t("cms.nodes", default: nil)).to be_blank
    end
  end
end
