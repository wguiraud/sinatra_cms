require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'tilt/erubis'

root = File.expand_path("..", __FILE__)

def valid_files(root)
  Dir.glob(root + "/data/*.txt").map do |path|
    File.basename(path)
  end
end

get "/" do 
  @files = valid_files(root)

  erb :index 
end

get "/:file_name" do 
  if valid_files(root).include?(params[:file_name])
    file_path = root + "/data/" + params[:file_name]
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else 
    
  end

end

