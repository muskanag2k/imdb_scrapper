require 'rspec'
require_relative '../bin/imdb_scrapper'

RSpec.describe IMDb do
  
  before(:each) do
    @imdb_obj = IMDb.new
  end

  describe '#print_movies' do
    it 'prints top movies from the database' do
      movies = @imdb_obj.print_top_movies(3)
      puts movies
      puts
    end
  end

  describe '#fetch_actors' do
    it 'fetches actors from a valid movie URL' do
      actors = @imdb_obj.fetch_actors('https://www.imdb.com/title/tt0111161/fullcredits')
      puts actors.first(5)
    end
  end

end
