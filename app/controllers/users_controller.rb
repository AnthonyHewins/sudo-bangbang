require 'concerns/permission'

class UsersController < ApplicationController
  include Permission

  before_action :set_and_authorize, only: %i[edit update destroy]
  before_action :authorize, only: %i[change_password update_password]

  UPDATE = 'User was successfully updated.'.freeze
  DELETE = "User successfully deleted.".freeze
  PW_MISMATCH = "New password and confirm password do not match".freeze
  ORIGINAL_PW_INCORRECT = "Current password was incorrect. Enter current password to change it to new password.".freeze

  def index
    @users = User.all
  end

  def show
    @user = User.includes(:articles).find(params[:id])
  end
 
  def edit
  end
  
  def update
    if @user.update(user_params)
      redirect_to @user, flash: {green: UPDATE}
    else
      flash.now[:red] = @user.errors
      render :edit
    end
  end

  def destroy
    if @user.destroy
      redirect_to users_path, flash: {info: DELETE}
    else
      flash.now[:red] = @user.errors
      redirect_to @user
    end
  end

  def update_password
    if params[:new] == params[:confirm]
      change_password current_user.authenticate(params[:current])
    else
      error PW_MISMATCH, 'change_password'
    end
  end
  
  private
  def user_params
    params.require(:user).permit(:handle, :profile_picture)
  end

  def change_password(user)
    if user
      try_change_password user, params[:new]
    else
      error ORIGINAL_PW_INCORRECT, 'change_password'
    end
  end

  def try_change_password(user, new_pw)
    if user.update(password: new_pw)
      redirect_to user, flash: {info: "Successfully changed password."}
    else
      error user.errors, 'change_password'
    end
  end
  
  def error(msg, render_path)
    flash.now[:red] = msg
    render render_path
  end
end
