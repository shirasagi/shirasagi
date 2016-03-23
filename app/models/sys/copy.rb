class Sys::Copy
  include ActiveModel::Model

  attr_accessor :name, :host, :domains, :copy_site, :copy_contents

  #NOTE: 以下だとバリデーションが働かなかった
  validates :name, presence: true
  validates :host, presence: true
  validates :domains, presence: true
  validates :copy_site, presence: true

end
