class TasksController < ApplicationController
  before_action :set_task, only: %i[ show edit update destroy ]

  def index
    @task = Task.new
    @tasks = current_user.tasks.where(is_done: :not_started).order(:position)
    @done_tasks_by_date = current_user.tasks.where(is_done: :closed).where.not(done_at: nil).order(done_at: :desc).group_by { |task| task.done_at.to_date }
  end

  def show
    @task = current_user.tasks.find(params[:id])
    render partial: "tasks/components/task_row", locals: { task: @task }
  end

  def new
    @task = current_user.tasks.build
  end

  def edit
    @task = current_user.tasks.find(params[:id])
    render partial: "tasks/components/form", locals: { task: @task }
  end

  def create
    @task = current_user.tasks.build(task_params)

    respond_to do |format|
      if @task.save
        @task.insert_at(1)
        format.turbo_stream
        format.html { redirect_to tasks_path, notice: "タスクを登録しました" }
        format.json { render :show, status: :created, location: @task }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_task_form",
            partial: "tasks/components/form",
            locals: { task: @task }
          )
        end
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @task = current_user.tasks.find(params[:id])
    respond_to do |format|
      if @task.update(task_params)
        format.turbo_stream
        format.html { redirect_to tasks_path, notice: "タスクを更新しました" }
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
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def split_create
    @parent_task = current_user.tasks.find(params[:id])
    child_tasks_params = params[:tasks] || []

    @child_tasks = child_tasks_params.values.map do |task_param|
      current_user.tasks.new(task_param.merge(parent_id: @parent_task.id))
    end

    if @child_tasks.all?(&:save)
      respond_to do |format|
        format.turbo_stream # ← 追加
        format.html { redirect_to tasks_path, notice: "分割タスクを登録しました" }
      end
    else
      render :split, status: :unprocessable_entity
    end
  end


  def update_status
    @task = current_user.tasks.find(params[:id])

    if params[:task][:is_done] == "closed"
      success = @task.update(is_done: :closed, done_at: Time.current)
    else
      success = @task.update(is_done: :not_started, done_at: nil)
    end

    @done_tasks_by_date = current_user.tasks.where(is_done: :closed)
                          .where.not(done_at: nil)
                          .order(done_at: :desc)
                          .group_by { |task| task.done_at.to_date }

    respond_to do |format|
      if success
        format.turbo_stream
        format.html { redirect_to tasks_path, notice: "ステータスを更新しました" }
      else
        format.html { redirect_to tasks_path, alert: "ステータス更新に失敗しました" }
      end
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

  def split_dispatch
    @parent_task = current_user.tasks.find(params[:id])
    input_tasks = params[:tasks] || []

    @child_tasks = input_tasks.map do |task_param|
      current_user.tasks.create!(
        title: task_param[:title],
        memo: task_param[:memo],
        estimated_time: task_param[:estimated_time],
        parent_task_id: @parent_task.id,
        is_done: :not_started
      )
    end

    @parent_task.update(is_done: :splited)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to tasks_path, notice: "分割しました" }
    end
  end

  def reorder
    task = current_user.tasks.find(params[:id])
    direction = params[:direction]

    case direction
    when "up"
      task.move_higher
    when "down"
      task.move_lower
    when "top"
      task.move_to_top
    when "bottom"
      task.move_to_bottom
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to tasks_path, notice: "順番を変更しました" }
    end
  end

    
  private

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :memo, :estimated_time, :is_done, :recurrence_interval, :priority_level, :parent_task_id, :position)
  end


  def build_split_prompt(parent_task, filled_tasks)
    filled_info = filled_tasks.map.with_index(1) do |task, i|
      lines = []
      lines << "▼ 子タスク #{i}"
      lines << "タイトル: #{task["title"]}" if task["title"].present?
      lines << "所要時間: #{task["estimated_time"]}" if task["estimated_time"].present?
      lines << "メモ: #{task["memo"]}" if task["memo"].present?
      lines.join("\n")
    end.join("\n\n")

    Rails.logger.debug "=== filled_info ===\n#{filled_info}"

    <<~PROMPT
      親タスク: #{parent_task.title}
      所要時間: #{parent_task.estimated_time || "未設定"}分
      モチベーションメモ: #{parent_task.memo}

      以下の子タスクを補完してください。
      - タイトルがある場合は、タイトルに合ったメモと所要時間を補ってください
      - タイトルがない場合は、親タスクの内容に沿って新しくタイトルとメモを考えてください
      - メモは、タイトルに忠実に内容を補足してください（親タスクの文脈に引っ張られすぎないようにしてください）
      - 所要時間も推測して補完してください（数値のみで、単位不要）
      - 各子タスクは親タスクの具体的な分割であり、将来的にさらに細分化される可能性があります
      - 誰にでも当てはまる表現（年齢・性別・環境に依存しない）にしてください
      - 出力に番号や「子タスク○」などは含めないでください

      現在の子タスク入力内容：
      #{filled_info}

      出力形式（各子タスクごと）：
      タイトル: ...
      所要時間: ...（数値のみ）
      メモ: ...（動機づけや具体性のある内容）

      ※出力されるメモは、各子タスクの「タイトルの内容を補足・説明する」ためのものにしてください。親タスクの文脈だけに依存しないように注意してください。

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
