require File.dirname(__FILE__) + '/../spec_helper'

describe "pending statuses", :shared => true do
  it "#next retrieves next status" do
    @status.followup.should == @new
  end
  
  it "skips processing if no followup is found" do
    @status.followup = :false
    @status.hours.should == 0
    @status.should be_pending
    @status.process!
    @status.should be_pending
  end
end

describe Status, "in pending state with followup in same project" do
  # it_should_behave_like "pending statuses"

  define_models :copy => :statuses do
    model Status do
      stub :new_in_same_project, :message => '@abc new_in_same_project', :created_at => (current_time - 2.hours), :project => all_stubs(:project)
    end
  end

  before do
    @new    = statuses(:new_in_same_project)
    @status = statuses(:pending)
    @new.code_and_message = @new.message
  end

  {0 => 0.0, 10 => (1.0/6.0), 15 => 0.25, 25 => (25.0/60.0), 30 => 0.5, 45 => 0.75}.each do |min, result|
    it "processes @status hours in quarters at #{min} minutes past the hour" do
      @new.created_at = @new.created_at + min.minutes
      @new.save!

      @status.hours.should == 0
      @status.should be_pending
      @status.process!
      @status.should be_processed
      @status.hours.to_s.should == (3.0.to_f + result).to_s
    end
  end
end

describe Status, "in pending state with followup in no project" do
  # it_should_behave_like "pending statuses"

  define_models :copy => :statuses do
    model Status do
      stub :new_without_project, :message => 'new_without_project', :created_at => (current_time - 2.hours)
    end
  end

  before do
    @new    = statuses(:new_without_project)
    @status = statuses(:pending)
  end

  {0 => 0.0, 10 => 0.25, 15 => 0.25, 25 => 0.5, 30 => 0.5, 45 => 0.75}.each do |min, result|
    it "processes @status hours in quarters at #{min} minutes past the hour" do
      @new.created_at = @new.created_at + min.minutes
      @new.save

      @status.hours.should == 0
      @status.should be_pending
      @status.process!
      @status.should be_processed
      @status.hours.to_s.should == (3.to_f + result).to_s
    end
  end
end

describe Status, 'permissions' do
  define_models do
    model User do
      stub :other, :login => 'other'
      stub :admin, :login => 'admin', :admin => true
    end
    
    model Status do
      stub :other_in_project, :message => 'other-in-project', :user => all_stubs(:other_user), :created_at => current_time - 47.hours, :project => all_stubs(:project)
    end
  end
  
  before do
    @status = statuses :default
  end
  
  it "allow status owner to edit" do
    @status.should be_editable_by(users(:default))
  end
  
  it "allow admin to edit" do
    @status.should be_editable_by(users(:admin))
  end
  
  it "allow project owner to edit" do
    statuses(:other_in_project).should be_editable_by(users(:default))
  end
  
  it "restrict other user from editing" do
    @status.should_not be_editable_by(users(:other))
  end
  
  it "restrict nil user from editing" do
    @status.should_not be_editable_by(nil)
  end
end

describe Status, "(filtering by date)" do
  define_models :copy => false do
    time 2007, 6, 30, 6

    model User do
      stub :login => 'bob'
      stub :other, :login => 'fred'
    end

    model UserContext do
      stub :name => "Foo", :permalink => 'foo', :user => all_stubs(:user)
    end

    model Membership do
      stub :user => all_stubs(:user), :context => all_stubs(:context), :project_id => 1
    end

    model Status do
      stub :message => 'default', :aasm_state => 'processed', :hours => 5, :created_at => current_time - 5.minutes, :user => all_stubs(:user), :project_id => 1
      stub :status_day, :message => 'status_day', :created_at => current_time - 8.minutes, :user => all_stubs(:other_user), :project_id => 2
      stub :status_week_1, :message => 'status_week_1', :created_at => current_time - 3.days
      stub :status_week_2, :message => 'status_week_2', :created_at => current_time - (4.days + 20.hours), :user => all_stubs(:other_user)
      stub :status_biweek_1, :message => 'status_biweek_1', :created_at => current_time - 8.days, :user => all_stubs(:other_user)
      stub :status_biweek_2, :message => 'status_biweek_2', :created_at => current_time - (14.days + 20.hours)
      stub :status_month_1, :message => 'status_month_1', :created_at => current_time - 20.days, :user => all_stubs(:other_user)
      stub :status_month_2, :message => 'status_month_2', :created_at => current_time - (28.days + 20.hours)
      stub :archive, :message => 'archive', :created_at => current_time - 35.days
      stub :uncounted, :message => 'uncounted', :created_at => current_time - 2.minutes, :project_id => nil
    end
  end
  
  before do
    @old = Time.zone
    Time.zone = -28800
    @user  = users :default
    @other = users :other
    @ctx   = contexts :default
  end
  
  after do
    Time.zone = @old
  end
  
  it "shows recent statuses with no filter" do
    compare_stubs :statuses, Status.filter(nil, nil)[0], [:uncounted, :default, :status_day, :status_week_1, :status_week_2,
      :status_biweek_1, :status_biweek_2, :status_month_1, :status_month_2, :archive]
  end
  
  it "counts recent status hours with no filter" do
    Status.filtered_hours(nil, nil).total.should == 9 * 5
    Status.hours(nil, nil).should == 9 * 5
  end
  
  it "shows recent statuses by user" do
    expected = [:uncounted, :default, :status_week_1,  :status_biweek_2, :status_month_2, :archive]
    compare_stubs :statuses, Status.filter(@user.id, nil)[0], expected
    compare_stubs :statuses, @user.statuses.filter(nil)[0],   expected
  end
  
  it "counts recent status hours by user with no filter" do
    Status.filtered_hours(@user.id, nil).total.should == 5 * 5
    Status.hours(@user.id, nil).should == 5 * 5
    @user.statuses.filtered_hours(nil).total.should   == 5 * 5
    @user.statuses.hours(nil).should   == 5 * 5
  end
  
  it "shows today's statuses" do
    compare_stubs :statuses, Status.filter(nil, :daily)[0], [:uncounted, :default, :status_day]
  end
  
  it "counts today's status hours" do
    Status.filtered_hours(nil, 'daily').total.should == 2 * 5
    Status.hours(nil, 'daily').should == 2 * 5
  end
  
  it "shows today's statuses by user" do
    expected = [:uncounted, :default]
    compare_stubs :statuses, Status.filter(@user.id, 'daily')[0], expected
    compare_stubs :statuses, @user.statuses.filter('daily')[0],   expected
  end
  
  it "counts today's status hours by user" do
    Status.filtered_hours(@user.id, 'daily').total.should == 5
    @user.statuses.filtered_hours('daily').total.should   == 5
    Status.hours(@user.id, 'daily').should == 5
    @user.statuses.hours('daily').should   == 5
  end
  
  it "shows this week's statuses" do
    compare_stubs :statuses, Status.filter(nil, 'weekly')[0], [:uncounted, :default, :status_day, :status_week_1, :status_week_2]
  end
  
  it "shows this week's statuses by context" do
    compare_stubs :statuses, Status.filter(nil, :weekly, :context => @ctx)[0], [:default, :status_week_1, :status_week_2]
  end
  
  it "counts this week's status hours" do
    Status.filtered_hours(nil, 'weekly').total.should == 4 * 5
    Status.hours(nil, 'weekly').should == 4 * 5
  end
  
  it "counts this week's status hours by context" do
    Status.filtered_hours(nil, 'weekly', :context => @ctx).total.should == 3 * 5
    Status.hours(nil, 'weekly', :context => @ctx).should == 3 * 5
  end
  
  it "shows this week's statuses by user" do
    expected = [:uncounted, :default, :status_week_1]
    compare_stubs :statuses, Status.filter(@user.id, 'weekly')[0], expected
    compare_stubs :statuses, @user.statuses.filter[0],             expected
  end
  
  it "counts this week's status hours by user" do
    Status.filtered_hours(@user.id, 'weekly').total.should == 2 * 5
    @user.statuses.filtered_hours('weekly').total.should   == 2 * 5
    Status.hours(@user.id, 'weekly').should == 2 * 5
    @user.statuses.hours('weekly').should   == 2 * 5
  end
  
  it "shows this fortnight's statuses" do
    compare_stubs :statuses, Status.filter(nil, 'bi-weekly')[0], [:uncounted, :default, :status_day, :status_week_1, :status_week_2, :status_biweek_1, :status_biweek_2]
  end
  
  it "counts this fortnight's status hours" do
    Status.filtered_hours(nil, 'bi-weekly').total.should == 6 * 5
    Status.hours(nil, 'bi-weekly').should == 6 * 5
  end
  
  it "shows this fortnight's statuses by user" do
    expected = [:uncounted, :default, :status_week_1, :status_biweek_2]
    compare_stubs :statuses, Status.filter(@user.id, 'bi-weekly')[0], expected
    compare_stubs :statuses, @user.statuses.filter('bi-weekly')[0],   expected
  end
  
  it "counts this fortnight's status hours by user" do
    Status.filtered_hours(@user.id, 'bi-weekly').total.should == 3 * 5
    @user.statuses.filtered_hours('bi-weekly').total.should   == 3 * 5
    Status.hours(@user.id, 'bi-weekly').should == 3 * 5
    @user.statuses.hours('bi-weekly').should   == 3 * 5
  end
  
  it "shows earlier fortnight's statuses" do
    Time.stub!(:now).and_return(Time.utc(2007, 6, 14, 6))
    compare_stubs :statuses, Status.filter(nil, 'bi-weekly')[0], [:status_month_1, :status_month_2]
  end
  
  it "counts earlier fortnight's status hours" do
    Time.stub!(:now).and_return(Time.utc(2007, 6, 14, 6))
    Status.filtered_hours(nil, 'bi-weekly').total.should == 2 * 5
    Status.hours(nil, 'bi-weekly').should == 2 * 5
  end
  
  it "shows earlier fortnight's statuses by user" do
    Time.stub!(:now).and_return(Time.utc(2007, 6, 14, 6))
    expected = [:status_month_2]
    compare_stubs :statuses, Status.filter(@user.id, 'bi-weekly')[0], expected
    compare_stubs :statuses, @user.statuses.filter('bi-weekly')[0],   expected
  end
  
  it "counts earlier fortnights's status hours by user" do
    Time.stub!(:now).and_return(Time.utc(2007, 6, 14, 6))
    Status.filtered_hours(@user.id, 'bi-weekly').total.should == 5
    @user.statuses.filtered_hours('bi-weekly').total.should   == 5
    Status.hours(@user.id, 'bi-weekly').should == 5
    @user.statuses.hours('bi-weekly').should   == 5
  end
  
  it "shows this month's statuses" do
    compare_stubs :statuses, Status.filter(nil, 'monthly')[0],  [:uncounted, :default, :status_day, :status_week_1, :status_week_2, :status_biweek_1, :status_biweek_2, :status_month_1, :status_month_2]
  end
  
  it "counts this month's status hours" do
    Status.filtered_hours(nil, 'monthly').total.should == 8 * 5
    Status.hours(nil, 'monthly').should == 8 * 5
  end
  
  it "shows this month's statuses by user" do
    expected = [:uncounted, :default, :status_week_1, :status_biweek_2, :status_month_2]
    compare_stubs :statuses, Status.filter(@user.id, 'monthly')[0], expected
    compare_stubs :statuses, @user.statuses.filter('monthly')[0],   expected
  end
  
  it "counts this month's status hours by user" do
    Status.filtered_hours(@user.id, 'monthly').total.should == 4 * 5
    @user.statuses.filtered_hours('monthly').total.should   == 4 * 5
    Status.hours(@user.id, 'monthly').should == 4 * 5
    @user.statuses.hours('monthly').should   == 4 * 5
  end
end

describe_validations_for Status, :user_id => 1, :message => 'foo bar' do
  presence_of :user_id, :message
end