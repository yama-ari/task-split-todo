class ChangeDefaultAndNullOnDailyActivities < ActiveRecord::Migration[7.2]
  def up
    # nil のデータを false に置き換え（null: false 制約でエラーが出ないように）
    DailyActivity.where(morning_logged_in: nil).update_all(morning_logged_in: false)
    DailyActivity.where(evening_logged_in: nil).update_all(evening_logged_in: false)

    # デフォルトと null 制約を追加
    change_column_default :daily_activities, :morning_logged_in, from: nil, to: false
    change_column_null :daily_activities, :morning_logged_in, false

    change_column_default :daily_activities, :evening_logged_in, from: nil, to: false
    change_column_null :daily_activities, :evening_logged_in, false
  end

  def down
    change_column_null :daily_activities, :morning_logged_in, true
    change_column_default :daily_activities, :morning_logged_in, from: false, to: nil

    change_column_null :daily_activities, :evening_logged_in, true
    change_column_default :daily_activities, :evening_logged_in, from: false, to: nil
  end
end
