class Task < ApplicationRecord
  acts_as_list
  enum is_done: { not_started: 0, closed: 1 }

  belongs_to :user
  belongs_to :parent_task, class_name: 'Task', optional: true

  validates :title, presence: true, length: { minimum: 3, maximum: 20 }
  # validates :memo, allow_blank: true, length: { minimum: 3, maximum: 100 }
  # validates :estimated_time, allow_blank: true, numericality: true

  def is_done_text
    I18n.t("activerecord.attributes.task.is_done_values.#{is_done}")
  end
end
