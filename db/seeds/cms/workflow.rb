# --------------------------------------
# Require

@group = Cms::Group.find_by name: 'シラサギ市'
@admin = Cms::User.find_by(uid: "admin")
@user1 = Cms::User.find_by(uid: "user1")

# --------------------------------------
# Seed

def save_workflow_route(data)
  if item = Workflow::Route.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Workflow::Route.new(data)
  item.save
  item
end

puts "# workflow"

approvers = Workflow::Extensions::Route::Approvers.new(
  [ { level: 1, user_id: @user1.id }, { level: 2, user_id: @admin.id } ]
)
required_counts = Workflow::Extensions::Route::RequiredCounts.new(
  [ false, false, false, false, false ]
)
save_workflow_route name: "多段承認", group_ids: [@group.id],
  approvers: approvers, required_counts: required_counts
