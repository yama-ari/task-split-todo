class TasksController < ApplicationController
  before_action :set_task, only: %i[ show edit update destroy ]

  # GET /tasks or /tasks.json
  def index
    @tasks = current_user.tasks.where(is_done: :not_started).order(:position)
  end

  # GET /tasks/1 or /tasks/1.json
  def show; end

  # GET /tasks/new
  def new
    @task = current_user.tasks.build
  end

  # GET /tasks/1/edit
  def edit
  end

  # POST /tasks or /tasks.json
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

  # PATCH/PUT /tasks/1 or /tasks/1.json
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

  # DELETE /tasks/1 or /tasks/1.json
  def destroy
    @task.destroy!

    respond_to do |format|
      format.html { redirect_to tasks_path, status: :see_other, notice: "Task was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def move_higher
    Task.find(params[:id]).move_higher # viewで選択したtaskを一つ上の並び順に変更する
    redirect_to tasks_path
  end
 
  def move_lower
    Task.find(params[:id]).move_lower # viewで選択したtaskを一つ下の並び順に変更する
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
    task_params_array = params.dig(:tasks, :tasks) || []
    @parent_task = current_user.tasks.find(params[:id])
    parent_position = @parent_task.position

    @parent_task.update(is_done: :splited)

    current_user.tasks.where("position > ?", parent_position).update_all("position = position + #{task_params_array.size}")

    task_params_array.each_with_index do |param, index|
      permitted = param.permit(:title, :memo, :estimated_time, :is_done, :recurrence_interval, :priority_level, :parent_task_id, :position)
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = current_user.tasks.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.require(:task).permit(:title, :memo, :estimated_time, :is_done, :recurrence_interval, :priority_level, :parent_task_id, :position)
    end
end
