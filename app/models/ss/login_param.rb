class SS::LoginParam
  include ActiveModel::Model

  attr_accessor :email
  attr_accessor :password
  attr_accessor :remember_me
end
