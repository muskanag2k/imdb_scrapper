class CreateActorDbs < ActiveRecord::Migration[6.1]
  def change
    create_table :actor_dbs do |t|
      t.string :name

      t.timestamps
    end
  end
end
