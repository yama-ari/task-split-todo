class ChangeIsDoneDefaultInTasks < ActiveRecord::Migration[7.2]
  def change
    change_column_default :tasks, :is_done, 0
  end
end
