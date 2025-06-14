json.extract! task, :id, :title, :memo, :estimated_time, :is_done, :recurrence_interval, :priority_level, :user_id, :parent_task_id, :position, :created_at, :updated_at
json.url task_url(task, format: :json)
