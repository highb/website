class AddAllowCommentsByDefaultToUserPreferences < ActiveRecord::Migration[7.0]
  def change
    return if Rails.env.production?

    add_column :user_preferences, :allow_comments_by_default, :boolean
  end
end
