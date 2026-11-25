require 'spec_helper'

describe History::Backup, type: :model, dbscope: :example do
  # mongoid.models にモデルの登録がない場合、履歴を表示できないので登録されているかテストする
  context "all models which include 'history/addon/backup' are under mongoid.models" do
    it do
      models = Mongoid.models.select { |m| m.include?(History::Addon::Backup) }
      expect(models).to have_at_least(150).items

      models.sort_by { _1.name }.each do |m|
        key = m.model_name.i18n_key
        expect(I18n.t(key, scope: "mongoid.models", default: nil)).to be_present, "#{key} が mongoid.models に未定義です。"
      end
    end
  end

  context "all models under mongoid.models are existed" do
    it do
      I18n.t("mongoid.models").keys.map(&:to_s).each do |model_name|
        expect { model_name.camelize.constantize }.to_not raise_error, "#{model_name} が未定義です。翻訳だけが残っています。"

        model = model_name.camelize.constantize
        expect(model.include?(Mongoid::Document)).to be_truthy, "#{model_name} は Mongoid::Document ではありません。"
      end
    end
  end
end
