class Gws::Circular::Comment
  include ActiveModel::Model
  include SS::PermitParams
  extend SS::Document::ClassMethods

  PARENT_CLASS = Gws::Circular::Post

  attr_accessor :name, :text, :user_id, :site_id, :created, :updated,
                :parent, :id, :in_updated, :cur_user, :cur_site
  permit_params :name, :text, :user_id, :site_id, :created, :updated

  def allowed?(action, user, opts = {})
    return user_id == user.id if user_id
    parent.allowed?(:read, user, opts)
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
    parent.set_seen(user) if parent.unseen?(user)
    parent.add_comment(attributes).update
  end

  def update
    self.updated = Time.zone.now
    parent.set_seen(user) if parent.unseen?(user)
    parent.update_comment(id, attributes).update
  end

  def destroy
    parent.delete_comment(id).update
  end

  def user
    @user ||= Gws::User.find(user_id)
  end

end
