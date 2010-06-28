class Job::UserInviter < Job::Base.new(:project, :user)

  def perform
    if user.is_a? User
      User::Mailer.deliver_project_invitation project, user
    elsif user.is_a? Invitation
      User::Mailer.deliver_new_invitation project, user
    else
      raise "Unsupported invitation type '#{user.class}'"
    end
  end

end
