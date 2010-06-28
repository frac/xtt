require 'delayed_job' # app/models/delayed_job.rb
Delayed::Job.destroy_failed_jobs = false
