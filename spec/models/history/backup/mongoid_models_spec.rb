require 'spec_helper'

describe History::Backup, type: :model, dbscope: :example do
  # mongoid.models にモデルの登録がない場合、履歴を表示できないので登録されているかテストする
  it do
    models = Mongoid.models.select { |m| m.include?(History::Addon::Backup) }
    expect(models).to have_at_least(150).items

    models.sort_by { _1.name }.each do |m|
      key = m.model_name.i18n_key
      expect(I18n.t(key, scope: "mongoid.models", default: nil)).to be_present, "#{key} が mongoid.models に未定義です。"
    end
  end
end
