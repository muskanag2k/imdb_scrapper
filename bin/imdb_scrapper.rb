#!/usr/bin/env ruby
require 'nokogiri'
require 'http'
require 'json'
require 'pg'
require 'redis'

class IMDb

  def initialize
    @db = PG.connect(dbname: 'imdb_scrapper_development')
    @redis = Redis.new(url: 'redis://localhost:6379/0')
  end

  def fetch_movies
    url = 'https://www.imdb.com/chart/top/?ref_=nv_mv_mpm'
    response = HTTP.headers('User-Agent' => 'Mozilla/5.0').get(url)
    if response.status.success?
      body = response.body.to_s
      html = Nokogiri::HTML(body)
      script_tag = html.at('script[type="application/ld+json"]')
      json_data = JSON.parse(script_tag.content)

      cached_data = @redis.get(url)
      encode_response = Base64.strict_encode64(JSON.pretty_generate(json_data))
      if !cached_data or cached_data != encode_response
        insert_updated_movies(json_data)
        @redis.set(url, encode_response)
      else
        puts "No update."
      end
      json_data
    else
      puts "Error fetching the IMDb Top 250 page: #{response.status}"
    end
  end

  def print_top_movies(n)
    json_data = fetch_movies
    items = json_data['itemListElement']
    items.first(n).each do |item|
      movie_name = item['item']['name']
      movie_id = insert_movie(movie_name)
      cast_url = item['item']['url']
      Thread.new do
        actors = fetch_actors(cast_url)
        actors_ids = actors.map { |actor_name| insert_actor(actor_name) }
        actors_ids.each do |actor_id|
          insert_actor_movie_mapping(movie_id, actor_id)
        end
      end
    end

    puts "Top #{n} movies...."
    print_movies (n)
  rescue StandardError => e
    puts "Error fetching or parsing data: #{e.message}"
  end

  def fetch_actors(cast_url)
    cast_response = HTTP.headers('User-Agent' => 'Mozilla/5.0').get(cast_url)
    actors = []
    if cast_response.status.success?
      cast_body = cast_response.body.to_s
      cast_html = Nokogiri::HTML(cast_body)
      actors = cast_html.css('a[href^="/name/"]').map { |actor| actor.text.strip }.uniq
      actors.delete("")
    end
    actors
  end

  def insert_movie(name)
    existing_movie = @db.exec_params("SELECT id FROM movies WHERE name = $1", [name])
    if existing_movie.ntuples == 0
      result = @db.exec_params("INSERT INTO movies (name, created_at, updated_at) VALUES ($1, NOW(), NOW()) RETURNING id", [name])
      result[0]['id'].to_i
    else
      existing_movie[0]['id'].to_i
    end
  end

  def insert_actor(name)
    existing_actor = @db.exec_params("SELECT id FROM actors WHERE name = $1", [name])

    if existing_actor.ntuples == 0
      result = @db.exec_params("INSERT INTO actors (name, created_at, updated_at) VALUES ($1, NOW(), NOW()) RETURNING id", [name])
      result[0]['id'].to_i
    else
      existing_actor[0]['id'].to_i
    end
  end

  def insert_actor_movie_mapping(movie_id, actor_id)
    @db.exec_params("INSERT INTO actor_movies (movie_id, actor_id, created_at, updated_at) VALUES ($1, $2, NOW(), NOW())", [movie_id, actor_id])
  end

  def print_movies(n = 5)
    result = @db.exec <<-SQL
      SELECT movies.name AS movie_name
      FROM movies
      LIMIT #{n};
    SQL

    result.each_with_index do |row, index|
      puts "#{index+1}. #{row['movie_name']}"
    end
  end

  def fetch_movies_by_actor(actor_name, m = 2)
    puts "Top #{m} movies of #{actor_name}.."
    result = @db.exec <<-SQL
      SELECT M.name AS movie_name
      FROM movies M
      INNER JOIN actor_movies AM
      ON AM.movie_id = M.id
      INNER JOIN actors A
      ON A.id = AM.actor_id
      WHERE A.name = '#{actor_name}'
      GROUP BY AM.actor_id, M.name
      LIMIT #{m};
    SQL

    result.each_with_index do |row, index|
      puts "#{index+1}. #{row['movie_name']}"
    end
  end

  def insert_updated_movies(data)
    if data
      json_data = data
      items = json_data['itemListElement']

      items.each do |item|
        movie_name = item['item']['name']
        movie_id = insert_movie(movie_name)
        cast_url = item['item']['url']

        Thread.new do
          actors = fetch_actors(cast_url)
          actors_ids = actors.map { |actor_name| insert_actor(actor_name) }

          actors_ids.each do |actor_id|
            insert_actor_movie_mapping(movie_id, actor_id)
          end
        end
      end
    else
      puts "Error fetching the IMDb Top 250 page: #{response.status}"
    end

  rescue StandardError => e
    puts "Error fetching or parsing data: #{e.message}"
  end

end


imdb_obj = IMDb.new

if ARGV.length == 1
  command = ARGV.first.to_i
  if(command.is_a? Integer)
    imdb_obj.print_top_movies(command)
  else
    puts "wrong input!!"
  end
elsif ARGV.length == 2
  imdb_obj.fetch_movies_by_actor(ARGV[0], ARGV[1].to_i)
else
  puts "Wrong input!!"
end
