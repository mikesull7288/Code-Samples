require 'rubygems'

require 'json'
require 'net/https'
require 'open-uri'
require 'openssl'
require 'cgi'

require 'sinatra'
require 'haml'
require 'sass'



def asana(url)
  uri = URI.parse("https://app.asana.com/api/1.0/" + url)
  puts uri.path
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  header = {
    "Content-Type" => "application/json"
  }
  req = Net::HTTP::Get.new(uri.path, header)
  req.basic_auth(@@api_key, '')
  return http.start { |http| http.request(req) }
end

def asanaprojects(workspace_id)
  #taskpaper file output
  filename = "tasks.taskpaper"
  target = File.open(filename, 'w')
  # target.write("foo")
  # target.close()


  all_projects = []
  all_res = []

  res = asana("workspaces/" + workspace_id + "/projects")
  body = JSON.parse(res.body)

  if body['errors'] then
    puts "Server returned an error: #{body['errors'][0]['message']}"
  else
    # put all project IDs in an array
    body.fetch("data").each do |projects|
      all_projects.push(projects.fetch("id"))
    end

    all_projects.each do |project|
      r = asana("projects/" + project.to_s)
      rr = JSON.parse(r.body)
      rrr = rr.fetch("data")
      if rrr.fetch("archived") == false
        target.write(rrr.fetch("name")+":\n")
        # if rrr.fetch("notes").downcase.include? 'statusboard' then
          target.write(rrr.fetch("name")+":\n")
          # all_res.store(project.to_s, rrr)
          tasks = asana("projects/" + project.to_s + "/tasks")
          tbody = JSON.parse(tasks.body)
          tbody.fetch("data").each do |task|
            t = asana("tasks/" + task.fetch("id").to_s)
            tr = JSON.parse(t.body)
            trr = tr.fetch("data")
            if trr.fetch("completed") == false then
              target.write("\t- "+trr.fetch("name")+" @"+trr.fetch("assignee_status")+"\n")
              puts(("     - "+trr.fetch("name")+" @"+trr.fetch("assignee_status")+"\n"))
              all_res.push(trr)
            end
          # end
        end
      end
    end
    target.close()
    return all_res
  end
end

def asanatasks(project_id)
  
  tasks = asana("projects/" + project_id + "/tasks?assignee=me")
  tbody = JSON.parse(tasks.body)
  tbody.fetch("data").each do |task|
    t = asana("tasks/" + task.fetch("id").to_s)
    tr = JSON.parse(t.body)
    trr = tr.fetch("data")
    if trr.fetch("completed") == false then
      all_res.push(trr)
    end
  end
  return all_res
end



get '/:api_key/:workspace_id' do
  @@api_key = params[:api_key]
  workspace_id = params[:workspace_id]
  @tasks = asanaprojects(workspace_id)
  # @projects.each_key do |project_id|
#     @tasks.add( asanaprojects(project_id) )
#   end
  haml :index, :format => :html5
end
