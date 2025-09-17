module ApplicationHelper
  include Heroicon::Engine.helpers
  def activity_color_code(activity)
    return "#F3F4F6" if activity.nil? # ← グレー

    level = [activity&.morning_logged_in, activity&.evening_logged_in].count(true)

    case level
      when 0 then "#DCFCE7"
      when 1 then "#BBF7D0" 
      when 2 then "#86EFAC"
      else "#F3F4F6"  
    end
  end
end
