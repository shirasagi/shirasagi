class Gws::Workflow2::RouteMigrationJob < Gws::ApplicationJob
  include Job::Gws::TaskFilter

  self.task_name = 'gws:workflow2_route_migration'

  def perform
    Rails.logger.tagged(site.name) do
      each_route do |route|
        migrate_route(route)

        task.log "#{route.name}: 移行しました。"
      end
    end
  end

  private

  def each_route
    criteria = Gws::Workflow::Route.all.site(site)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |item|
        Rails.logger.tagged(item.name) do
          yield item
        end
      end
    end
  end

  def migrate_route(route)
    new_route = Gws::Workflow2::Route.new
    # Gws::Workflow2::Route <= Workflow::Model::Route
    new_route.name = route.name
    new_route.order = next_order
    new_route.pull_up = route.pull_up
    new_route.on_remand = route.on_remand
    new_route.approvers = convert_approvers(route.approvers)
    new_route.required_counts = route.required_counts
    new_route.approver_attachment_uses = route.approver_attachment_uses
    new_route.circulations = convert_circulations(route.circulations)
    new_route.circulation_attachment_uses = route.circulation_attachment_uses
    new_route.remark = "migrated from #{route.name}(#{route.id}) at #{Time.zone.now.iso8601}"
    # Gws::Reference::Site
    new_route.cur_site = self.site
    new_route.site = self.site
    # Gws::Addon::Workflow2::RouteReadableSetting
    new_route.readable_setting_range = "public"
    # Gws::Addon::Workflow2::RouteGroupPermission <= Gws::GroupPermission
    new_route.group_ids = route.group_ids
    new_route.user_ids = route.user_ids
    new_route.custom_group_ids = route.custom_group_ids

    new_route.save!
  end

  def next_order
    @next_order ||= begin
      order = Gws::Workflow2::Route.unscoped.max(:order)
      order || 10
    end

    @next_order += 10
    @next_order
  end

  def convert_approvers(approvers)
    return [] if approvers.blank?

    approvers.map do |approver|
      next unless approver[:user_id].numeric?
      new_approver = {
        "level" => approver[:level], "user_id" => approver[:user_id].to_i, "user_type" => Gws::User.name
      }
      new_approver["editable"] = approver[:editable] if approver.key?(:editable)
      new_approver
    end
  end

  def convert_circulations(circulations)
    return [] if circulations.blank?

    circulations.map do |circulation|
      next unless circulation[:user_id].numeric?
      new_circulation = {
        "level" => circulation[:level], "user_id" => circulation[:user_id].to_i, "user_type" => Gws::User.name
      }
      new_circulation
    end
  end
end
