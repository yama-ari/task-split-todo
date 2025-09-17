class PagesController < ApplicationController
  def terms
  end

  def privacy
  end

  def dashboard
    start_date = Date.today.beginning_of_week - 4.weeks
    end_date = Date.today.end_of_week
    date_range = (start_date..end_date).to_a

    @weeks = date_range.each_slice(7).to_a
    @weeks_grouped_by_month = date_range
      .group_by(&:beginning_of_month)
      .transform_values { |days| days.each_slice(7).to_a }

    @activities_by_date = current_user.daily_activities.where(date: date_range).index_by(&:date)
  end
end
