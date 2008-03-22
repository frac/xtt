class StatusesController < ApplicationController
  before_filter :find_status,    :only => [:show, :edit, :update, :destroy]
  before_filter :login_required

  # USER SCOPE
  
  def index
    @statuses ||= current_user.statuses

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml  => @statuses }
    end
  end

  def new
    @status = Status.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml  => @status }
    end
  end

  def create
    if params[:submit] == 'Out'
      unless params[:status][:code_and_message].blank?
        params[:status][:code_and_message].sub! /@\w*/, ''
        params[:status][:code_and_message].strip!
      end
      params[:status][:code_and_message] = "Out" if params[:status][:code_and_message].blank?
    end
    @status  = current_user.post params[:status][:code_and_message]

    respond_to do |format|
      if @status.new_record?
        format.html   { render :action => "new" }
        format.iphone { render :action => "new" }
        format.xml    { render :xml  => @status.errors, :status => :unprocessable_entity }
      else
        format.html   { redirect_after_status }
        format.iphone { redirect_after_status }
        format.xml  { render :xml  => @status, :status => :created, :location => @status }
      end
    end
  end

  # GLOBAL SCOPE
  include ApplicationHelper
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @status }
      format.js   { render :text => nice_time(@status.accurate_time) }
    end
  end

  def update
    respond_to do |format|
      if @status.update_attributes(params[:status])
        flash[:notice] = 'Status was successfully updated.'
        format.html { redirect_to(@status) }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml  => @status.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @status.destroy
    respond_to do |format|
      format.html { redirect_to(statuses_url) }
      format.xml  { head :ok }
    end
  end
  
protected
  def authorized?
    logged_in? && (admin? || @status.nil? || @status.editable_by?(current_user))
  end

  def find_status
    @status = Status.find(params[:id])
  end
  
  def redirect_after_status
    if params[:destination] && params[:destination].first == '/'
      redirect_to params[:destination]
    else
      redirect_to @status.project || root_path
    end
  end
end
