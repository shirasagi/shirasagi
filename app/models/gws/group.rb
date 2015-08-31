class Gws::Group
  include SS::Model::Group

  has_many :users, foreign_key: :group_ids, class_name: "Gws::User"
end
