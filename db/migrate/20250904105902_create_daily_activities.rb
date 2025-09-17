class CreateDailyActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :daily_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.boolean :morning_logged_in
      t.boolean :evening_logged_in

      t.timestamps
    end
  end
end
