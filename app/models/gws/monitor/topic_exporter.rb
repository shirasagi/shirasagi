class Gws::Monitor::TopicExporter
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :item

  def enum_csv(encoding:, download_comment:)
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_item(drawer)
      draw_group(drawer)
      draw_comment(drawer)
    end

    enum = Enumerator.new do |yielder|
      item.attend_groups.each_with_index do |group, group_index|
        comments = item.comment(group.id)
        case download_comment
        when 'all'
          if comments.count > 0
            comments.each_with_index do |comment, comment_index|
              yielder << [ group, group_index, comment, comment_index ]
            end
          else
            yielder << [ group, group_index, nil, 0 ]
          end
        else # 'last'
          yielder << [ group, group_index, comments.last, 0 ]
        end
      end
    end

    drawer.enum(enum, encoding: encoding, model: Gws::Monitor::Topic)
  end

  private

  def draw_item(drawer)
    drawer.column :id do
      drawer.head { I18n.t('gws/monitor.csv')[0] }
      drawer.body do |group, group_index, comment, comment_index|
        if group_index == 0 && comment_index == 0
          item.id
        end
      end
    end
    drawer.column :name do
      drawer.head { I18n.t('gws/monitor.csv')[1] }
      drawer.body do |group, group_index, comment, comment_index|
        if group_index == 0 && comment_index == 0
          item.name
        end
      end
    end
  end

  def draw_group(drawer)
    drawer.column :answer_state do
      drawer.head { I18n.t('gws/monitor.csv')[2] }
      drawer.body do |group, group_index, comment, comment_index|
        if comment_index == 0
          item.answer_state_name(group)
        end
      end
    end
    drawer.column :group_name do
      drawer.head { I18n.t('gws/monitor.csv')[3] }
      drawer.body do |group, group_index, comment, comment_index|
        if comment_index == 0
          group.name
        end
      end
    end
  end

  def draw_comment(drawer)
    drawer.column :comment_contributor_name do
      drawer.head { I18n.t('gws/monitor.csv')[4] }
      drawer.body do |group, group_index, comment, comment_index|
        comment.try(:contributor_name)
      end
    end
    drawer.column :comment_text do
      drawer.head { I18n.t('gws/monitor.csv')[5] }
      drawer.body do |group, group_index, comment, comment_index|
        comment.try(:text)
      end
    end
    drawer.column :comment_updated do
      drawer.head { I18n.t('gws/monitor.csv')[6] }
      drawer.body do |group, group_index, comment, comment_index|
        updated = comment.try(:updated)
        if updated
          I18n.l(updated, format: :picker)
        end
      end
    end
  end
end
