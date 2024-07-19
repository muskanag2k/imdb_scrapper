class CreateMovieDbs < ActiveRecord::Migration[6.1]
  def change
    create_table :movie_dbs do |t|
      t.string :name

      t.timestamps
    end
  end
end
