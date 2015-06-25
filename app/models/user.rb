class User < ActiveRecord::Base
   acts_as_authentic
  BASE_URL = 'http://172.16.4.67/PMToolWebService/PMTool.asmx'
  def self.authenticate_with_salt(id,cookie_salt)
    user = ''
    url = URI.parse(BASE_URL+'?op=GetEmployeeById')
    request = Net::HTTP::Post.new(url.path)
    request.content_type="text/xml"
    request.content_length=405
    request.body="<?xml version='1.0' encoding='utf-8'?><soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><GetEmployeeById xmlns='http://tempuri.org/'><EmployeeID>"+id.to_s+"</EmployeeID></GetEmployeeById></soap:Body></soap:Envelope>"
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)} 
    data = XmlSimple.xml_in(response.body)
    details = data["Body"][0]["GetEmployeeByIdResponse"][0]["GetEmployeeByIdResult"][0]["diffgram"][0]["Employee"]
    if !details.nil?
      user_name = details[0]["ASSOCIATE_NAME"]
      user_id = details[0]["ASSOCIATE_ID"]
      pwd = details[0]["PASSWORD"]
      user = {}
      user["name"] = user_name
      user["id"] = user_id
      user["password"] = pwd
    end
    (user && user["salt"] == cookie_salt) ? user : nil
    puts user
  end
   
end
