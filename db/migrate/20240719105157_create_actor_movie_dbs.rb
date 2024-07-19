class CreateActorMovieDbs < ActiveRecord::Migration[6.1]
  def change
    create_table :actor_movie_dbs do |t|
      t.references :actor_db, null: false, foreign_key: true
      t.references :movie_db, null: false, foreign_key: true

      t.timestamps
    end
  end
end
