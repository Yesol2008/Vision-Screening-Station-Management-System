<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="io.github.cdimascio.dotenv.DotenvException" %>
<%@ page import="java.time.format.DateTimeParseException" %>
<%@ page import="java.time.LocalDate" %>

<%@ include file="/auth/participantGuard.jsp" %>
<%

//getting error and success
String successMsg = request.getParameter("msg");
String errCode = request.getParameter("errCode");

String successMessage ="";
String errorCode ="";
//setting values of the error/success messages if there is any
if("withdrawn".equals(successMsg)){
	successMessage = "Event Withdrawn Successfully";
}else if("registered".equals(successMsg)){
	successMessage = "Event Registered Successfully";	
}

if("failedWithdrawn".equals(errCode)){
	errorCode = "Failed to withdraw the event";
}else if("failedRegistration".equals(errCode)){
	errorCode = "Faild to register the event";	
}else if("Exception".equals(errCode)){
	errorCode ="Unable to connect to the server for signup/withdrawal. Please try again later.";
}

//Make a value containes url of current page. it will be sent to signup.jsp 
//when actions like sign up, or sign up again is performed in signup.jsp page
//this is because signup.jsp handles the signup, signup again, and withdrawal of the events
//and it is linked with mySignups.jsp as well. once the action is done signup.jsp will redirect users
//back to the page that they were at before according to this returnUrl
String returnUrl = "mySignups.jsp";
Integer participantId = (Integer) session.getAttribute("userId");
			
			
List<Map<String, String>> signups = new ArrayList<>();
LocalDate today = LocalDate.now();			
			
try {
	
	// Step 1: Load environment variables
	Dotenv dotenv =  Dotenv.configure()
	        .directory(application.getRealPath("/WEB-INF"))
	        .load();;

	String connURL = dotenv.get("DB_URL");
	String username = dotenv.get("DB_USERNAME");
	String password = dotenv.get("DB_PASSWORD");


    // Step 2: Load JDBC Driver (optional for newer drivers)
    Class.forName("com.mysql.cj.jdbc.Driver");
    		
    		
    		
	String sql = "{CALL get_participant_registered(?)}";
	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
			CallableStatement cs = conn.prepareCall(sql)){
			cs.setInt(1, participantId);
			
			
			try(ResultSet rs = cs.executeQuery();){
				
				while(rs.next()){
					//putting values into hashmap with key and value
					 Map<String, String> ev = new HashMap<>();
						ev.put("id", String.valueOf(rs.getInt("event_id")));
						ev.put("name", rs.getString("event_name"));
						ev.put("location", rs.getString("location"));
						ev.put("status", rs.getString("status"));
						ev.put("regStatus", rs.getString("registration_status"));
						ev.put("regId", String.valueOf(rs.getInt("registration_id")));
						java.sql.Date d = rs.getDate("event_date");
						ev.put("date", d == null ? "" : d.toString());
						boolean past = !ev.get("date").isEmpty()&& LocalDate.parse(ev.get("date")).isBefore(today);
						ev.put("past", String.valueOf(past));
						signups.add(ev);      
  				
				}
			}
		}
			
	} catch (SQLException e) {
		System.err.println("Database error in mySignups.jsp"+ e);
	    errorCode="Unable to connect to the server. Please try again later.";
	} catch (DotenvException e) {
		System.err.println("Environment configuration error in mySignups.jsp"+ e);
		errorCode="Something went wrong. Please try again later.";


	} catch (DateTimeParseException e) {
		System.err.println("Invalid event date format in mySignups.jsp"+ e);
		errorCode = "Unable to display event information. Please try again later.";

	}catch (Exception e) {
	    e.printStackTrace();
	  	System.err.println("Database connection error"+ e);
	 	out.println("Unable to connect to the database.");
	}
			
%>			

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Events Registered - Vision Screening</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>


<div class="page">

<%@ include file="/shared/header.jsp" %>


	<div class="titleRow">
			<h1>My Sign-up's</h1>
	</div>
	<p class="intro">View and manage the events that you have registered.</p>
	<div class="card">
			<% if (!successMessage.isEmpty()) { %>
    			<p class="msgBox msgSuccess"><%= successMessage %></p>
			<% } %>
			<% if (!errorCode.isEmpty()) { %>
    			<p class="msgBox msgError"><%= errorCode %></p>
			<% } %>
	
	
			<table class="dataTable">
				<tr>
					<th>Event</th>
					<th>Date/Location</th>
					<th>Status</th>
					<th>My Sign up</th>
					<th>Action</th>
				</tr>
<%			
			for (Map<String, String> ev : signups) {
				String event_name = ev.get("name");
				String event_date = ev.get("date");
			    String registration_id   = ev.get("regId");
			    String registrationStatus = ev.get("regStatus");
			    String location = ev.get("location");
			    String status    = ev.get("status");
			    boolean past     = Boolean.parseBoolean(ev.get("past"));

					
%>
				<tr>
					<td><%=escapeHtml(event_name) %></td>
					<td><%=escapeHtml(event_date)%>/<br><%=location %></td>
					<td><%=escapeHtml(status)%></td>
					<td><%=escapeHtml(registrationStatus)%></td>
					<td>
<% 					 if(past ||"Completed".equals(status) ||"Inactive".equals(status) || "Attended".equals(registrationStatus)){ %>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>>" method="post">
						<input type="submit" class="btn btnPrimary" value="Withdawal Closed" disabled>
						</form>
					<%}else if("Registered".equals(registrationStatus)){ %>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Withdraw">
							<input type="hidden" name="registrationIdForWithraw" value="<%=registration_id%>">
						</form>
					<% } else if("Withdrawn".equals(registrationStatus)){%>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign-up again">
							<input type="hidden" name="registrationId" value="<%=registration_id%>">
						</form>
					<%}%>
					</td>
				</tr>



<%				}%>


			</table>
	</div>
	<%@ include file="/shared/footer.html" %>

</div>


</body>
</html>