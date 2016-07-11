module Board::Model::AnpiPost
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site

  included do
    store_in collection: "board_anpi_posts"

    seqid :id
    # 氏名
    field :name, type: String
    # 氏名（かな）
    field :kana, type: String
    # 電話番号
    field :tel, type: String
    # 住所
    field :addr, type: String
    # 性別
    field :sex, type: String
    # 年齢
    field :age, type: String
    # メールアドレス
    field :email, type: String
    # メッセージ
    field :text, type: String

    permit_params :name, :kana, :tel, :addr, :sex, :age, :email, :text

    validates :name, presence: true, length: { maximum: 80 }
    validates :text, presence: true
  end

  def sex_options
    %w(male female).map { |m| [ I18n.t("member.options.sex.#{m}"), m ] }.to_a
  end
end
