class TasksController < ApplicationController
  before_action :set_task, only: %i[ show edit update destroy ]

  def index
    @tasks = current_user.tasks.where(is_done: :not_started).order(:position)
  end

  def show; end

  def new
    @task = current_user.tasks.build
  end

  def edit; end

  def create
    @task = current_user.tasks.build(task_params)

    respond_to do |format|
      if @task.save
        @task.insert_at(1)
        format.html { redirect_to @task, notice: "Task was successfully created." }
        format.json { render :show, status: :created, location: @task }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to @task, notice: "Task was successfully updated." }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @task.destroy!
    respond_to do |format|
      format.html { redirect_to tasks_path, status: :see_other, notice: "Task was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def move_higher
    Task.find(params[:id]).move_higher
    redirect_to tasks_path
  end

  def move_lower
    Task.find(params[:id]).move_lower
    redirect_to tasks_path
  end

  def move_to_top
    Task.find(params[:id]).move_to_top
    redirect_to tasks_path
  end

  def move_to_bottom
    Task.find(params[:id]).move_to_bottom
    redirect_to tasks_path
  end

  def split
    @parent_task = current_user.tasks.find(params[:id])
    @child_tasks = Array.new(3) { current_user.tasks.build(parent_task_id: @parent_task.id) }
  end

  def split_create
    @parent_task = current_user.tasks.find(params[:id])
    parent_position = @parent_task.position

    task_params_array = (params.dig(:tasks, :tasks) || []).map do |param|
      param.permit(:title, :memo, :estimated_time, :is_done, :recurrence_interval, :priority_level, :parent_task_id, :position)
    end

    @parent_task.update(is_done: :splited)

    current_user.tasks.where("position > ?", parent_position).update_all("position = position + #{task_params_array.size}")

    task_params_array.each_with_index do |permitted, index|
      task = current_user.tasks.create(permitted.merge(position: parent_position + index))
      unless task.save
        Rails.logger.warn "タスク保存に失敗しました: #{task.errors.full_messages.join(", ")}"
      end
    end

    redirect_to tasks_path, notice: "タスクを分割して登録しました"
  end

  def update_status
    @task = current_user.tasks.find(params[:id])
    if @task.update(is_done: params[:task][:is_done])
      redirect_to tasks_path, notice: "ステータスを更新しました"
    else
      redirect_to tasks_path, alert: "ステータス更新に失敗しました"
    end
  end

  def split_with_ai
    @parent_task = current_user.tasks.find(params[:id])

    task_keys = [:title, :estimated_time, :memo, :is_done, :recurrence_interval, :priority_level, :parent_task_id, :position]

    input = params.require(:tasks).permit("0" => task_keys, "1" => task_keys, "2" => task_keys).to_h || {}
    filled_tasks = input.map { |_, task_params| task_params }

    parent_position = @parent_task.position

    if params[:commit] == "register"
      @parent_task.update(is_done: :splited)

      filled_tasks.each_with_index do |task_params, index|
        current_user.tasks.create(
          task_params.merge(
            parent_task_id: @parent_task.id,
            is_done: :not_started,
            position: parent_position + index
          )
        )
      end

      redirect_to tasks_path, notice: "分割タスクを登録しました"
      return
    end

    if params[:commit] == "ai"
      prompt = build_split_prompt(@parent_task, filled_tasks)
      response = OpenaiService.call(prompt)
      completed_tasks = parse_split_response(response)

      @child_tasks = input.each_with_index.map do |(_, original_params), i|
        ai_params = completed_tasks[i] || {}

        merged_params = original_params.merge(ai_params) do |_, user_val, ai_val|
          user_val.blank? || user_val == "未入力" ? ai_val : user_val
        end

        Task.new(merged_params.merge(is_done: :not_started, parent_task_id: @parent_task.id))
      end

      Rails.logger.debug "=== AIの返答 ==="
      Rails.logger.debug response
      render :split
    end
  end


  private
  def split_dispatch
    @parent_task = current_user.tasks.find(params[:id])
    input_tasks = params[:tasks] || []

    if params[:commit] == "ai"
      redirect_to split_with_ai_task_path(@parent_task), params: { tasks: input_tasks }
    else
      redirect_to split_create_task_path(@parent_task), params: { tasks: input_tasks }
    end
  end

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :memo, :estimated_time, :is_done, :recurrence_interval, :priority_level, :parent_task_id, :position)
  end


  def build_split_prompt(parent_task, filled_tasks)
    filled_info = filled_tasks.each_with_index.map do |task, i|
      <<~TEXT
        子タスク#{i + 1}:
        タイトル: #{task["title"]}
        所要時間: #{task["estimated_time"]}
        メモ: #{task["memo"]}
      TEXT
    end.join("\n")

    <<~PROMPT
      親タスク: #{parent_task.title}
      所要時間: #{parent_task.estimated_time || "未設定"}分
      モチベーションメモ: #{parent_task.memo}

      以下の子タスクを補完してください。
      - タイトルがある場合はそのままにしてメモだけ補完
      - タイトルがない場合は、親タスクの内容に沿ってタイトルとメモを新たに考える
      - 所要時間もできるだけ推測して補完してください
      - 各子タスクは、親タスクをさらに細かく分けていくためのものです
      - 将来的に各子タスクもさらに分割する可能性があるため、タイトルはなるべく具体的にしてください
      - タイトルは「親タスクとの関係性」が明確になるようにしてください。
      - メモやタイトルは、誰でも使える中立的な表現にしてください
        （家庭環境・人生経験・年齢・性別などに依存しない内容にしてください）
      - 番号や「子タスク○」などは不要です

      既に入力された子タスク情報：
      #{filled_info}
      Rails.logger.debug "=== filled_info ==="
      Rails.logger.debug filled_info

      出力形式（3セット）：
      タイトル: ...
      所要時間: ...（数値のみ、単位不要）
      メモ: ...（誰にでも当てはまるモチベーションが上がるような内容)
    PROMPT
  end


  def parse_split_response(text)
    text.split(/タイトル:/).drop(1).map do |chunk|
      {
        "title" => chunk[/^(.*?)\n/, 1],
        "estimated_time" => chunk[/所要時間:\s*(.*?)\n/, 1]&.to_i,
        "memo" => chunk[/メモ:\s*(.*?)$/, 1]
      }.compact
    end
  end
end
