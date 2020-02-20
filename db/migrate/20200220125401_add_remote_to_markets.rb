class AddRemoteToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :metadata_encrypted, :string, limit: 1024, after: :position
  end
end
