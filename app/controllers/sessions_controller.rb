class SessionsController < ApplicationController
  require 'net/http'
  require 'xmlsimple'
  BASE_URL = 'http://172.16.4.67/PMToolWebService/PMTool.asmx'
  def new
  end
  
  def create
    id = params[:user_id]
    password = params[:password]
    url = URI.parse(BASE_URL+'?op=Login')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=405
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><Login xmlns='http://tempuri.org/'><EmployeeId>"+id+"</EmployeeId><Password>"+password+"</Password></Login></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)} 
    data = XmlSimple.xml_in(response.body)
    details = data["Body"][0]["LoginResponse"][0]["LoginResult"][0]["diffgram"][0]["Login"]
    puts "detalis on create"
    puts details
    if !details.nil?
      user_name = details[0]["Table"][0]["ASSOCIATE_NAME"]
      user_id = details[0]["Table"][0]["ASSOCIATE_ID"]
      pwd = details[0]["Table"][0]["PASSWORD"]
      user = {}
      user["name"] = user_name
      user["id"] = user_id
      user["password"] = pwd
      sign_in user
      redirect_to daily_status_path      
    else
      flash[:message] = "Invalid email/password combination."
      render 'new'
    end
  end
  
  def destroy
    sign_out
    redirect_to root_path    
  end
end
