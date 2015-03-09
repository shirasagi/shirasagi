class Chorg::Runner
  include Chorg::Loggable
  include Chorg::MongoidSupport

  MAIN = "main".freeze
  TEST = "test".freeze

  def self.call_async(*args, &block)
    type = args.pop

    case type
    when MAIN then
      Chorg::MainRunner.call_async(*args, &block)
    when TEST then
      Chorg::TestRunner.call_async(*args, &block)
    else
      nil
    end
  end

  def initialize(config = SS.config.chorg)
    @config = config
    @models = config.models.map(&:constantize).freeze
    build_exclude_fields(config.exclude_fields)
  end

  def call(host, user, name, add_group_to_site)
    @cur_site = Cms::Site.find_by(host: host)
    @cur_user = Cms::User.site(@cur_site).or({id: user}, {name: user}).first if user.present?
    @add_group_to_site = add_group_to_site
    @item = Chorg::Revision.site(@cur_site).find_by(name: name)
    @item = Chorg::Revision.acquire_lock(@item, 1.hour.from_now)
    unless @item
      put_log("already running")
      return
    end

    Chorg::Revision.ensure_release_lock(@item) do
      @results = { "add" => { "success" => 0, "failed" => 0 },
                   "move" => { "success" => 0, "failed" => 0 },
                   "unify" => { "success" => 0, "failed" => 0 },
                   "division" => { "success" => 0, "failed" => 0 },
                   "delete" => { "success" => 0, "failed" => 0 } }
      @substituter = Chorg::Substituter.new
      @validation_substituter = Chorg::Substituter.new
      @delete_group_ids = []

      Chorg::ChangeSet::TYPES.each do |type|
        put_log("==#{type}==")
        with_inc_depth { @item.send("#{type}_change_sets").each(&method("execute_#{type}")) }
      end

      put_log("==update_all==")
      with_inc_depth { update_all }

      put_log("==validate_all==")
      with_inc_depth { validate_all }

      put_log("==delete_groups==")
      with_inc_depth { delete_groups(@delete_group_ids) }

      put_log("==results==")
      with_inc_depth do
        @results.keys.each do |key|
          put_log("#{key}: success=#{@results[key]["success"]}, failed=#{@results[key]["failed"]}")
        end
      end
    end
  end

  private
    def execute_add(changeset)
      put_log("add #{changeset.add_description}")
      destination = changeset.destinations.first
      group = find_or_create_group(destination)
      if save_or_collect_errors(group)
        put_log("created/updated group: #{group.name}(#{group.id})")
        @results["add"]["success"] += 1
      else
        @results["add"]["failed"] += 1
      end
      add_group_to_site(group)
    end

    def execute_move(changeset)
      put_log("move #{changeset.before_move} to #{changeset.after_move}")
      source = changeset.sources.first
      destination = changeset.destinations.first

      group = Cms::Group.where(id: source["id"]).first
      if group.blank?
        put_warn("group not found: #{source["name"]}(#{source["id"]})")
        return
      end

      source_attributes = copy_attributes_deeply(group)
      update_attributes(group, destination)
      if save_or_collect_errors(group)
        put_log("updated group: #{group.name}(#{group.id})")
        @results["move"]["success"] += 1
        @substituter.collect(source_attributes, group.attributes)
      else
        @results["move"]["failed"] += 1
      end
    end

    def execute_unify(changeset)
      put_log("unify #{changeset.before_unify} to #{changeset.after_unify}")
      destination = changeset.destinations.first
      destination_group = find_or_create_group(destination)
      unless save_or_collect_errors(destination_group)
        @results["unify"]["failed"] += 1
        return
      end

      put_log("created/updated group: #{destination_group.name}(#{destination_group.id})")
      @results["unify"]["success"] += 1

      add_group_to_site(destination_group)

      source_groups = changeset.sources.map do |source|
        Cms::Group.where(id: source["id"]).first
      end
      source_groups = source_groups.compact
      source_groups.each do |source_group|
        @substituter.collect(source_group.attributes, destination_group.attributes)
        next if source_group.id == destination_group.id
        move_users_group(source_group.id, destination_group.id)
        @delete_group_ids << source_group.id
      end
    end

    def execute_division(changeset)
      put_log("division #{changeset.before_division} to #{changeset.after_division}")
      source = changeset.sources.first
      source_group = Cms::Group.where(id: source["id"]).first
      if source_group.blank?
        put_warn("group not found: #{source["name"]}")
        return
      end

      destination_groups = changeset.destinations.map do |destination|
        find_or_create_group(destination)
      end

      success = destination_groups.reduce(true) do |a, e|
        next a if e.id == source_group.id
        if save_or_collect_errors(e)
          put_log("created group: #{e.name}")
          a
        else
          false
        end
      end

      if success
        @results["division"]["success"] += 1
      else
        @results["division"]["failed"] += 1
        return
      end

      destination_groups.each(&method(:add_group_to_site))

      destination_group_ids = destination_groups.map(&:id).to_a
      destination_attributes = copy_attributes_deeply(destination_groups.first)
      destination_attributes["_id"] = destination_group_ids

      # be careful, user's group_ids has only first division group.
      move_users_group(source_group.id, destination_group_ids.first)
      # group of page/node/layout/part has all division groups.
      @substituter.collect(source_group.attributes, destination_attributes)
      @delete_group_ids << source_group.id unless destination_group_ids.include?(source_group.id)
    end

    def execute_delete(changeset)
      source_groups = changeset.sources.map do |source|
        Cms::Group.where(id: source["id"]).first
      end
      source_groups.compact.each do |source_group|
        empty_attributes = {}
        source_group.attributes.select { |_, v| v.is_a?(Fixnum) }.each { |k, v| empty_attributes[k] = v }
        @validation_substituter.collect(source_group.attributes, empty_attributes)
        @delete_group_ids << source_group.id
      end
    end

    def update_all
      return if @substituter.empty?
      with_all_entity_updates(@models, @substituter) do |entity, updates|
        next if updates.blank?

        put_log("#{entity.name}(#{entity.url}) has some updates. module=#{entity.class}")
        with_inc_depth do
          updates.each do |k, new_value|
            old_value = entity[k]
            put_log("property #{k} has these changes:")
            with_inc_depth do
              if new_value.is_a?(String)
                Diffy::Diff.new(old_value, new_value, diff: "-U 3").to_s.each_line do |line|
                  next if /No newline at end of file/i =~ line
                  put_log("#{line.chomp}")
                end
              elsif new_value.is_a?(Array)
                convert_to_group_names(old_value - new_value).each do |name|
                  put_log("-#{name}")
                end
                convert_to_group_names(new_value - old_value).each do |name|
                  put_log("+#{name}")
                end
              else
                convert_to_group_names([old_value]).each do |name|
                  put_log("-#{name}")
                end
                convert_to_group_names([new_value]).each do |name|
                  put_log("+#{name}")
                end
              end
            end
          end
        end
        update_attributes(entity, updates)
        save_or_collect_errors(entity)
      end
    end

    def validate_all
      return if @validation_substituter.empty?
      with_all_entity_updates(@models, @validation_substituter) do |entity, deletes|
        put_log("#{entity.name}(#{entity.url}) has deleted attributes: #{deletes}") if deletes.present?
      end
    end
end
