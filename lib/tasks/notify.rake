require_relative '../../bin/imdb_scrapper'

namespace :notify do
  desc "To check if there are anymore movies uploaded on the site."
  task :movie_update => [ :environment ] do
    @imdb_obj = IMDb.new
    response = @imdb_obj.fetch_movies
    puts response
  end
end
