class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :memo
      t.integer :estimated_time
      t.integer :is_done
      t.string :recurrence_interval
      t.integer :priority_level
      t.integer :user_id
      t.integer :parent_task_id
      t.integer :position

      t.timestamps
    end
  end
end
