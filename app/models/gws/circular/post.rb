class Gws::Circular::Post
  include ActiveModel::Model
  include SS::PermitParams
  extend SS::Document::ClassMethods

  PARENT_CLASS = Gws::Circular::Topic

  attr_accessor :name, :text, :user_id, :site_id, :created, :updated, :parent, :id, :in_updated
  permit_params :name, :text, :user_id, :site_id, :created, :updated

  def allowed?(action, user, opts = {})
    PARENT_CLASS.allowed?(action, user, opts)
  end

  def attributes
    self.class.permitted_fields.
      reduce({}){ |ret, attr_name| ret[attr_name] = send attr_name; ret }
  end

  def attributes= (args)
    self.class.permitted_fields.each do |f|
      self.send("#{f}=", args[f]) if args.include?(f)
    end
  end

  def save
    self.updated = Time.zone.now
    self.created = self.updated unless self.created
    parent.add_comment(attributes).update
  end

  def update
    self.updated = Time.zone.now
    parent.update_comment(id, attributes).update
  end

  def destroy
    parent.delete_comment(id).update
  end

  def user
    @user ||= Gws::User.find(user_id)
  end

  # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::CircularPostJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::CircularPostJob.callback

end
