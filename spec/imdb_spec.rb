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

  describe '#fetch_movies_by_actor' do
    it 'fetch movies by actor' do
      movies = @imdb_obj.fetch_movies_by_actor('Morgan Freeman')
      puts movies
    end
  end

end
