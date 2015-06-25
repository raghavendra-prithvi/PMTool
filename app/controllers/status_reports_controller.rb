class StatusReportsController < ApplicationController
  require 'net/http'
  require 'xmlsimple'
  BASE_URL = 'http://172.16.4.67/PMToolWebService/PMTool.asmx'
  before_filter :require_user
  def user_details
    puts "inside user details"
    url = URI.parse(BASE_URL+'?op=GetEmployeeById')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=302
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><GetEmployeeById xmlns='http://tempuri.org/'><EmployeeID>"+@@user_id[0].to_s+"</EmployeeID></GetEmployeeById></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)} 
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    details1 = body[0]["GetEmployeeByIdResponse"][0]["GetEmployeeByIdResult"][0]["diffgram"][0]["Employee"]
    details = details1[0]["Table"] if !details1.nil?
    @user_name = details[0]["ASSOCIATE_NAME"][0]
    @role = details[0]["ACCESS_ROLE"][0]
  end
  
  def projects_list
    url = URI.parse(BASE_URL+'?op=GetProjects')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=302
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><GetProjects xmlns='http://tempuri.org/' /> </soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)} 
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    details1 = body[0]["GetProjectsResponse"][0]["GetProjectsResult"][0]["diffgram"][0]["Projects"]
    details = details1[0]["Table"] if !details1.nil?
    begin
       @projects = []
       @projects[0] = 'select'
       @projects1 = []
       @projects1[0] = 'select'
       details.each do |x|
          i = x["project_id"][0].to_i
          @projects1[i] = x["project_name"][0] if !x["project_name"][0].nil?
       end
         @projects = @projects1.compact
    rescue
      flash.now[:error] = 'No project Available'
    end
  end
  
  def task_list
    @hours = ['0.5','1.0','1.5','2.0','2.5','3.0','3.5','4.0']
    #get task details web services
    url = URI.parse(BASE_URL+'?op=GetTaskscategory')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=307
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><GetTaskscategory xmlns='http://tempuri.org/' /></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)} 
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    details1 = body[0]["GetTaskscategoryResponse"][0]["GetTaskscategoryResult"][0]["diffgram"][0]["TaskCategory"]
    details = details1[0]["Table"] if !details1.nil?
    @tasks = []
    @tasks[0] = 'Select'
    @billing_task = []
    begin
      details.each do |x|
          i = x["task_id"][0].to_i
          @tasks[i] = x["task_name"][0]
          @billing_task[i] = x["billable"][0]
      end
    rescue
      flash.now[:error] = "there is no tasks intitially"
    end
  end
  
  before_filter :projects_list,:task_list,:user_details
  def tasks_today
    res = {}
    rows = []    
    url = URI.parse(BASE_URL+'?op=GetTimeSheetForEmployee')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=307
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><GetTimeSheetForEmployee xmlns='http://tempuri.org/'><EmployeeID>"+@@user_id[0].to_s+"</EmployeeID></GetTimeSheetForEmployee></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)} 
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    details1 = body[0]["GetTimeSheetForEmployeeResponse"][0]["GetTimeSheetForEmployeeResult"][0]["diffgram"][0]["TimeSheet"]
    details = details1[0]["Table"] if !details1.nil?
    begin
      details.each do |x|
          row = Hash.new
          row[:id] = x["ASSOCIATE_TIMESHEET_ID"]
          @task_name = @tasks[x["TASK_CATEGORY_ID"][0].to_i]
          @project_name = @projects1[x["ASSOCIATE_PROJECT_ID"][0].to_i]
          row[:cell] = [@task_name, x["TASK_DESCRIPTION"][0].to_s, @project_name, x["HOURS"], x["BILLABLE_TASK"].to_s, x["TASK_START_DATE"][0].to_s, x["TASK_END_DATE"][0].to_s] 
          rows << row
      end
    rescue
      flash.now[:error] = "No tasks available for you."
    end
    res[:rows] =  rows
    render :json => res.to_json
  end
  
  before_filter :action=>'log_in',:controller=>'login'
  
  def daily
    
  end
  
  
  def assigned_tasks
    res = {}
    rows = []    
    url = URI.parse(BASE_URL+'?op=GetTasksAssignedTo')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=371
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><GetTasksAssignedTo xmlns='http://tempuri.org/'><EmployeeID>"+@@user_id[0].to_s+"</EmployeeID><StartDate></StartDate><EndDate></EndDate></GetTasksAssignedTo></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    details1 = body[0]["GetTasksAssignedToResponse"][0]["GetTasksAssignedToResult"][0]["diffgram"][0]["AssignedToTasks"]
    details = details1[0]["Table"] if !details1.nil?
    puts "details"
    puts body
    puts details1
    begin
      details.each do |x|
         row = Hash.new
         row[:id] = x["ASSOCIATE_TASK_ID"][0].to_i if !x["ASSOCIATE_TASK_ID"][0].nil?
         @task_name = @tasks[x["TASK_CATEGORY_ID"][0].to_i]
         @time = x["HOURS"][0] if !x["HOURS"].nil?
         @billable = x["BILLABLE_TASK"][0] if !x["BILLABLE_TASK"].nil?
         @task_description = x["TASK_DESCRIPTION"][0] if !x["TASK_DESCRIPTION"].nil?
         if !x["PROJECT_ID"].nil?
         @project_name = @projects1[x["PROJECT_ID"][0].to_i]
       else
         @project_name = ''
       end
         @created_date = x["TASK_CREATED_DATE"][0].to_s if !x["TASK_CREATED_DATE"].nil?
         @start_date = x["TASK_START_DATE"][0].to_s if !x["TASK_START_DATE"].nil?
         @end_date = x["TASK_END_DATE"][0].to_s if !x["TASK_END_DATE"].nil?
         @associate_id = x["ASSOCIATE_ID_ASSIGNED_BY"][0].to_s if !x["ASSOCIATE_ID_ASSIGNED_BY"].nil?
         row[:cell] = [@task_name.to_s, @task_description.to_s,@project_name, @time.to_s,@billable.to_s, @created_date.to_s,  @start_date.to_s, @end_date.to_s,@associate_id.to_s]if (!@task_name.nil?)
         rows << row
      end
    rescue
      flash.now[:error] = 'There are no Tasks Assigned to you'
    end
    res[:rows] =  rows
      render :json => res.to_json
  end
  
  def add_time_sheet
    @task_id = @tasks.index(params[:task])
    @project_id = @projects1.index(params[:project])
    url = URI.parse(BASE_URL+'?op=AddTimesheet')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=611
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><AddTimesheet xmlns='http://tempuri.org/'><TaskCategoryId>"+@task_id.to_s+"</TaskCategoryId><ProjectId>"+@project_id.to_s+"</ProjectId><Hours>"+params[:worked_time].to_s+"</Hours><TaskDescription>"+params[:task_description]+"</TaskDescription><StartDate>"+params[:start_date].to_s+"</StartDate><EndDate>"+params[:end_date].to_s+"</EndDate><Billable>"+ 0.to_s+"</Billable><EmployeeID>"+@@user_id[0].to_s+"</EmployeeID></AddTimesheet></soap:Body></soap:Envelope>"
    #request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><AddTimesheet xmlns='http://tempuri.org/'><TaskCategoryId>1</TaskCategoryId><ProjectId>2</ProjectId><Hours>1</Hours><TaskDescription>test999</TaskDescription><StartDate></StartDate><EndDate></EndDate><Billable>0</Billable><EmployeeID>01573</EmployeeID></AddTimesheet></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)} 
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    puts "body "
    puts body
    result = body[0]["AddTimesheetResponse"][0]["AddTimesheetResult"][0] 
    if result == 1
         render :text=> "successfully added Time sheet"
    else
         render :text=> body
    end
  end
  
  def add_task
    
  end
  def create_task
    @task_id = @tasks.index(params[:task])
    @project_id = @projects.index(params[:project])
    if params[:billable]=="on"
      @billable = 1
    else
      @billable = 0
    end
    url = URI.parse(BASE_URL+'?op=AddTask')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length= 759
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><AddTask xmlns='http://tempuri.org/'><TaskDesc>"+params[:task_description].to_s+"</TaskDesc><TaskCategory>"+@task_id.to_s+"</TaskCategory><AssignedBy>"+ @@user_id[0].to_s+"</AssignedBy><AssignedTo>"+ params[:assigned_to].to_s+"</AssignedTo><CreatedDate>"+ params[:start_date].to_s+"</CreatedDate><ProjectId>"+ @project_id.to_s+"</ProjectId><Hours>"+ params[:estimated_work_time].to_s+"</Hours><Billable>"+@billable.to_s+"</Billable></AddTask></soap:Body></soap:Envelope>"
    puts "request"
    puts request.body
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)} 
    task_data = XmlSimple.xml_in(response.body)
    puts "task data"
    puts task_data
    redirect_to :action=>'add_task'
  end
  
  
  def add_project
    
  end
  
  def create_project
    url = URI.parse(BASE_URL+'?op=AddProject')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length= 401
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><AddProject xmlns='http://tempuri.org/'><ProjectName>"+params[:project_name].to_s+"</ProjectName><CustomerSOWId>"+params[:customer_id].to_s+"</CustomerSOWId></AddProject></soap:Body></soap:Envelope>"
    puts "request in crdate prj"
    puts request.body
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    puts "body"
    puts body
    result = body[0]["AddProjectResponse"][0]["AddProjectResult"][0]
    if !result.nil?
      redirect_to(assign_project_path)
    else 
      redirect_to(add_project_path)
    end
  end
  
  def assign_project
    @project_id = @projects.index(params[:project])
    url = URI.parse(BASE_URL+'?op=AssignProjects')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length= 398
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><AssignProjects xmlns='http://tempuri.org/'><ProjectID>"+@project_id.to_s+"</ProjectID><AssociateID>"+params[:emp_ids].to_s+"</AssociateID></AssignProjects></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    begin
        result = body[0]["AssignProjectsResponse"][0]["AssignProjectsResult"][0]
    rescue
      flash[:notice] = "Assign new employees to the project"
    end
    flash[:notice] ="Successfully assigned projects."
  end
  
  def tasks_assigned_by_me
    res = {}
    rows = []
    @start_date = '2011-03-01'
    end_date = DateTime.now
    @end_date = end_date.to_s
    url = URI.parse(BASE_URL+'?op=GetTasksAssignedBy')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=439
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><GetTasksAssignedBy xmlns='http://tempuri.org/'><EmployeeID>"+@@user_id[0].to_s+"</EmployeeID><StartDate>"+@start_date+"</StartDate><EndDate>"+@end_date+"</EndDate></GetTasksAssignedBy></soap:Body></soap:Envelope>"
    puts "request body"
    puts request.body
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    task_data = XmlSimple.xml_in(response.body)
    body = task_data["Body"]
    details1 = body[0]["GetTasksAssignedByResponse"][0]["GetTasksAssignedByResult"][0]["diffgram"][0]["AssignedByTasks"]
    begin
      details = details1[0]["Table"] if !details1.nil?
      details.each do |x|
         @task_name = ''
         @time = ''
         @project_name = ''
         row = Hash.new
         row[:id] = x["ASSOCIATE_TASK_ID"][0].to_i if !x["ASSOCIATE_TASK_ID"].nil?
         @task_name = @tasks[x["TASK_CATEGORY_ID"][0].to_i] if !x["TASK_CATEGORY_ID"].nil?
         @time = x["HOURS"][0] if !x["HOURS"].nil?
         @billable = x["BILLABLE_TASK"][0] if !x["BILLABLE_TASK"].nil?
         @task_description = x["TASK_DESCRIPTION"][0] if !x["TASK_DESCRIPTION"].nil?
         if !x["PROJECT_ID"].nil?
         @project_name = @projects1[x["PROJECT_ID"].to_i]
       else
         @project_name = ''
       end
         @created_date = x["TASK_CREATED_DATE"][0].to_s if !x["TASK_CREATED_DATE"].nil?
         @start_date = x["TASK_START_DATE"][0].to_s if !x["TASK_START_DATE"].nil?
         @end_date = x["TASK_END_DATE"][0].to_s if !x["TASK_END_DATE"].nil?
         @associate_id = x["ASSOCIATE_ID_ASSIGNED_BY"][0].to_s if !x["ASSOCIATE_ID_ASSIGNED_BY"].nil?
         row[:cell] = [@task_name.to_s, @task_description.to_s,@project_name, @time.to_s,@billable.to_s, @created_date.to_s,  @start_date.to_s, @end_date.to_s,@associate_id.to_s]if (!@task_name.nil?)
         rows << row
      end
    rescue
      flash.now[:error] = 'There are no Tasks Assigned by you'
    end
      res[:rows] =  rows
      render :json => res.to_json
  
  end
 
  def update_task_status
    url = URI.parse(BASE_URL+'?op=GetTasksAssignedBy')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=439
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><UpdateTaskStatusByEmployee xmlns='http://tempuri.org/'><AsocaiteTaskId>"+params[:associate_task_id].to_s+"</AsocaiteTaskId><TaskFlag>"+params[:status].to_s+"</TaskFlag></UpdateTaskStatusByEmployee></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    task_data = XmlSimple.xml_in(response.body)
    begin
        body = task_data["Body"]
        result = body[0]["UpdateTaskStatusByEmployeeResponse"][0]["UpdateTaskStatusByEmployeeResult"][0]
        puts result.inspect
        if result == "1"
        render :text=>"1"
        else
          render :text=>"sorry unable to change the status"
        end
    rescue
      flash[:error] ="Cannot update he status"
    end
    
    
  end

  def employees
  end

  def all_employees_details
    res = {}
    rows = []
    puts "inside all employee details"
    url = URI.parse(BASE_URL+'?op=GetAllEmployees')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=306
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><GetAllEmployees xmlns='http://tempuri.org/' /></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    task_data = XmlSimple.xml_in(response.body)
    puts task_data
    puts "end"
    body = task_data["Body"]
    details = body[0]["GetAllEmployeesResponse"][0]["GetAllEmployeesResult"][0]["diffgram"][0]["NewDataSet"][0]["Table"]
    puts details
    details.each do |x|
         puts "inside details loop"
         puts x
         puts x["ACCESS_ROLE"]
         row = Hash.new
         row[:id] = x["ASSOCIATE_ROLE_ID"][0].to_i if !x["ASSOCIATE_ROLE_ID"].nil?
         associate_id = x["ASSOCIATE_ID"][0] if !x["ASSOCIATE_ID"].nil?
         associate_name = x["ASSOCIATE_NAME"][0] if !x["ASSOCIATE_NAME"].nil?
         access_role = x["ACCESS_ROLE"][0] if !x["ACCESS_ROLE"].nil?
         row[:cell] = [associate_id.to_s, associate_name.to_s,access_role.to_s]
         rows << row
         puts "end of loop"
     end
     res[:rows] =  rows
     render :json => res.to_json
  end
  
  def employee_timesheet
    puts "inside emloyee timesheet"
    puts params.inspect
  end
    
  def month
    
  end
end
