class RenameUserContextMembership < ActiveRecord::Migration
  def self.up
    rename_column :memberships, :context_id, :user_context_id
  end

  def self.down
    rename_column :memberships, :user_context_id, :context_id
  end
end
