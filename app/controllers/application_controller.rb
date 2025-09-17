class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :record_daily_activity_if_needed
  before_action :load_activity_grass_data
  include Devise::Controllers::Helpers
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

   private

  def record_daily_activity_if_needed
    return unless user_signed_in?

    now = Time.zone.now
    today = now.to_date

    activity = current_user.daily_activities.find_or_initialize_by(date: today)

    # すでに朝 or 夜が記録されていればスキップ（何度も更新しない）
    if now.hour < 12 && !activity.morning_logged_in
      activity.morning_logged_in = true
      activity.save
    elsif now.hour >= 18 && !activity.evening_logged_in
      activity.evening_logged_in = true
      activity.save
    end
  end

  def load_activity_grass_data
    return unless user_signed_in?

    start_date = Date.today.beginning_of_week
    end_date = Date.today.end_of_week
    date_range = (start_date..end_date).to_a

    @days_for_sidebar = date_range
    @activities_by_date_for_sidebar = current_user.daily_activities.where(date: date_range).index_by(&:date)
  end
end