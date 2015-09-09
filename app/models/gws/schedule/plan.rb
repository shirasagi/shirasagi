class Gws::Schedule::Plan
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Planable
  include Gws::Addon::GroupPermission

  #TODO: 繰り返しのデータの持ち方については、要検討
  belongs_to :repeat, class_name: 'Gws::Schedule::PlanRepeat'

  has_and_belongs_to_many :users, class_name: 'Gws::User' # rubocop:disable all

  #TODO: 設備予約
  #TODO: 公開範囲
  #TODO: 編集権限

  #TODO: 繰り返しのバリデーションを書く
  #TODO: 設備予約のバリデーションを書く
  #TODO: 公開範囲のバリデーションを書く
  #TODO: 編集権限のバリデーションを書く
end
