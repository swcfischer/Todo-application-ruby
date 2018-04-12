require "sinatra"
require "sinatra/reloader"
require 'sinatra/content_for'
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end


helpers do

  def h(content)
    Rack::Utils.escape_html(content)
  end

  def completed(list)
   return "complete" if list[:todos].all? { |todo| todo[:completed] } && !list[:todos].empty?
   ""
  end

  def incomplete_todos(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def sort_list(lists, &block)
    completed_list, incomplete_list = lists.partition { |list| completed(list) == "complete" }

    completed_list.each_with_index do |list|
      yield(list, lists.index(list))
    end

    incomplete_list.each_with_index do |list|
      yield(list, lists.index(list))
    end
  end

  def sort_todos(todos, &block)
    completed_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    completed_todos.each do |todo|
      yield(todo, todos.index(todo))
    end

    incomplete_todos.each do |todo|
      yield(todo, todos.index(todo))
    end
  end
end

before do
  session[:lists] ||= []
end

# Have home be lists

get '/' do 
  redirect '/lists'
end

# Display lists

get "/lists" do
  @lists = session[:lists]

  erb :lists, layout: :layout
end

get "/lists/new" do
  
  erb :new_list, layout: :layout
end

def valid_list_name?(list_name)
  if !(1..100).cover?(list_name.size)
    return "List name must be within 1 and 100 characters"
  elsif session[:lists].any? { |list| list[:name] == list_name}
    return "List name must be unique"
  end
  nil
end

# Add a list

post "/lists" do
  list_name = params[:list_name].strip
  error = valid_list_name?(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "A new list has been added"
    redirect "/lists"
  end
end

# Diplay List

get "/lists/:id" do
  @id_number = params[:id].to_i
  @list = session[:lists][@id_number]

  erb :list_view, layout: :layout
end

# Edit List

get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = session[:lists][@id]

  erb :edit_list, layout: :layout
end

# Edit list name

post "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  list_name = params[:list_name].strip
  error = valid_list_name?(list_name)
  @list_name = list_name
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists][@id][:name] = list_name
    session[:success] = "The list name has been changed"
    redirect "/lists/#{@id}"
  end
end

# Delete a list

post "/lists/:id/delete" do
  @id = params[:id].to_i
  @list = session[:lists][@id]

  session[:lists].delete(@list)
  session[:success] = "The list #{@list[:name]} has been deleted"
  redirect "lists"
end

# Add a todo

post "/lists/:id/todos" do
  @id_number = params[:id].to_i
  @list = session[:lists][@id_number] 
  todo = params[:todo].strip

  if !(1..60).cover? todo.length
    session[:error] = "Your todo must be between 1 and 60 characters"
    erb :list_view, layout: :layout
  else
    @list[:todos] << {name: "#{todo}", completed: false}
    session[:success] = "You have successfully added a todo to #{@list[:name]}"
    redirect "/lists/#{@id_number}"
  end
end

# Delete a todo

post "/lists/:id/todos/:todo_id/delete" do
  @id_number = params[:id].to_i
  @list = session[:lists][@id_number]
  @todo_id = params[:todo_id].to_i
  @list[:todos].delete_at(@todo_id)
  session[:success] = "The todo has been deleted"
  redirect "/lists/#{@id_number}"
end

# Complete a todo

post "/lists/:id/todos/:todo_id/complete" do
  is_completed = params[:completed] == "true"
  @id_number = params[:id].to_i
  @list = session[:lists][@id_number]
  @todo_id = params[:todo_id].to_i
  @todo = @list[:todos][@todo_id]
  @todo[:completed] = is_completed
  session[:success] = "The todo has been updated"
  redirect "/lists/#{@id_number}"

end

# Mark all todos as complete

post "/lists/:id/todos/complete/all" do
  @id_number = params[:id].to_i
  @list = session[:lists][@id_number]
  @todos = @list[:todos]
  
  @todos.each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos have been completed"
  redirect "/lists/#{@id_number}"
end




