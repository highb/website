class AddCommunityCheckedByToSamples < ActiveRecord::Migration[7.0]
  def change
    return if Rails.env.production?

    add_reference :training_data_code_tags_samples, :community_checked_by, null: true, foreign_key: { to_table: :users }, index: { name: "index_code_tags_samples_on_community_tagged_by_id" }, if_not_exists: true
  end
end