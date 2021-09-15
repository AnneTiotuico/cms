require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/content_for"
require "redcarpet"

configure do
  set :erb, :escape_html => true
  enable :sessions
  set :session_secret, 'secret'
end

root = File.expand_path("..", __FILE__)

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    render_markdown(content)
  end
end

get "/" do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index, layout: :layout
end

get "/:filename" do
  file_path = root + "/data/" + params[:filename]

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} doesn't exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  file_path = root + "/data/" + params[:filename]
  @filename = params[:filename]
  @file_contents = File.read(file_path)
  erb :edit_file, layout: :layout
end

post "/:filename" do
  # write to the current file and input the content from the user
  # show session message saying filename has been updated
  # redirect to "/" index page
  file_path = root + "/data/" + params[:filename]
  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end