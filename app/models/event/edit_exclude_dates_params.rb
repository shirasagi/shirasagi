class Event::EditExcludeDatesParams
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user, :event_recurrences

  attribute :index, :integer

  def cur_event_recurrence
    return @cur_event_recurrence if @cur_event_recurrence_found

    if event_recurrences[index].blank?
      @cur_event_recurrence = nil
      @cur_event_recurrence_found = true
      return
    end

    @cur_event_recurrence = Event::Extensions::Recurrence.demongoize(event_recurrences[index])
    @cur_event_recurrence_found = true
    @cur_event_recurrence
  end
end
