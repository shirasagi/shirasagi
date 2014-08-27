# coding: utf-8
class SS::User
  extend ActiveSupport::Autoload
  autoload :Model

  include SS::User::Model
end
