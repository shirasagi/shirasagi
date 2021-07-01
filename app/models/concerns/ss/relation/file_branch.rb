module SS::Relation::FileBranch
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    belongs_to :master, foreign_key: "master_id", class_name: self.to_s
  end
end
