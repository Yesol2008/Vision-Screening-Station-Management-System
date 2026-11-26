<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="io.github.cdimascio.dotenv.DotenvException" %>
<%@ page import="java.time.format.DateTimeParseException" %>
<%@ page import="java.time.LocalDate" %>


<%@ include file="/auth/participantGuard.jsp" %>


<%


//getting success and error
String successMsg = request.getParameter("msg");
String errCode = request.getParameter("errCode");

String successMessage ="";
String errorCode ="";

//set values in success or error messages if there is any
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
}else if("dbError".equals(errCode)){
	errorCode ="Something went wrong. Please try again later.";
}else if("invalidEventId".equals(errCode)){
	errorCode ="No such event exist.";
}else if("invalidRequest".equals(errCode)){
	errorCode ="Invalid request";
}

//getting participant id
Integer participantId = (Integer) session.getAttribute("userId");

//getting input values from search field and filter filed
String search = request.getParameter("search");
String statusFilter = request.getParameter("status");

//if the values in search field and filter filed is only '   ', set it as null
if (search != null && search.trim().isEmpty()) {
    search = null;
}
if (statusFilter != null && statusFilter.trim().isEmpty()) {
    statusFilter = null;
}

//Make a value containes url of current page. it will be sent to signup.jsp 
//when actions like sign up, or sign up again is performed in signup.jsp page
//this is because signup.jsp handles the signup, signup again, and withdrawal of the events
//and it is linked with mySignups.jsp as well. once the action is done signup.jsp will redirect users
//back to the page that they were at before according to this returnUrl
String returnUrl = "browseEvents.jsp";
List<Map<String, String>> events = new ArrayList<>();
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
    		    		
    String sql = "{CALL get_events_for_participant(?, ?, ?)}";
    
	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
		CallableStatement cs = conn.prepareCall(sql)){
			
			cs.setInt(1, participantId);
			cs.setString(2, search);
		    cs.setString(3, statusFilter);
		    
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
						 events.add(ev);      
   				
				}
			}
		}

	} catch (ClassNotFoundException e) {
		System.err.println("JDBC Driver not found"+ e);
		errorCode = "Unable to connect to the server. Please try again later.";
	} catch (SQLException e) {
		System.err.println("Database error in login.jsp"+ e);
		errorCode = "Unable to connect to the server. Please try again later.";

	}catch (DotenvException e) {
		System.err.println("Environment configuration error in browseEvents.jsp"+ e);
		errorCode="Something went wrong. Please try again later.";

	} catch (DateTimeParseException e) {
		System.err.println("Invalid event date format in browseEvents.jsp"+ e);
		errorCode = "Unable to display event information. Please try again later.";

	}catch (Exception e) {
	  	e.printStackTrace();
	   	application.log("Database connection error", e);
	   	out.println("Unable to connect to the database.");
}

%>	

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Browse Events - Vision Screening</title>
	<style>
	.card{
	display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
    padding: 20px;
	}
	.eventCard {
    background-color: white;
    border: 1px solid #ddd;
    border-radius: 12px;
    padding: 20px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}
	.searchBar{
	display: grid;
    grid-template-columns: 6fr 2fr 1fr;;
    gap: 20px;
    padding: 20px;
	}
	.btn:disabled {
    color: var(--ice);
    background-color: var(--greyLight);
    border-color: var(--grayLight);
    cursor: not-allowed;
	}
	.btn:disabled {
    color: var(--ice);
    background-color: var(--greyLight);
    border-color: var(--grayLight);
    cursor: not-allowed;
	}
	.btn:not(:disabled):hover {
    color: var(--ice);
    background-color: var(--greyLight);
    border-color: var(--grayLight);
	}
	
	</style>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
<div class="page">
<%@ include file="/shared/header.jsp" %>

	<div class="titleRow">
			<h1>Browse Event</h1>
	</div>
	<p class="intro">Browse and sign-up for vision-screening events.</p>
			<% if (!successMessage.isEmpty()) { %>
    			<p class="msgBox msgSuccess"><%= successMessage %></p>
			<% } %>
			<% if (!errorCode.isEmpty()) { %>
    			<p class="msgBox msgError"><%= errorCode %></p>
			<% } %>

			
		<form action="browseEvents.jsp" method="get" class="searchBar">
			<input type="text" class="grid" name="search" placeholder="Search event name..." value="<%= escapeHtml(search) %>">
			<select name="status" class="grid">
				<option value="">All Statuses</option>
				<option value="Upcoming" <%= "Upcoming".equals(statusFilter) ? "selected" : "" %>>Upcoming</option>
				<option value="Ongoing" <%= "Ongoing".equals(statusFilter) ? "selected" : "" %>>Ongoing</option>
				<option value="Completed" <%= "Completed".equals(statusFilter) ? "selected" : "" %>>Completed </option>
				<option value="Inactive" <%= "Inactive".equals(statusFilter) ? "selected" : "" %>>Inactive</option>
			</select>
		<button type="submit" class="btn btnPrimary">Search</button>
		</form>
			
		<div class="card">
<%			
			 for (Map<String, String> ev : events) {
			    String eventId   = ev.get("id");
			    String registrationStatus = ev.get("regStatus");
			    String status    = ev.get("status");
			    boolean past     = Boolean.parseBoolean(ev.get("past"));

%>
					<div class="eventCard">
					
						<h2><%= escapeHtml(ev.get("name")) %></h2>
							<p><strong>Date:</strong> <%= escapeHtml(ev.get("date")) %></p>
							<p><strong>Location:</strong> <%= escapeHtml(ev.get("location")) %></p>
							<p><strong>Status:</strong> <%= escapeHtml(status) %></p>
							<a href="viewEventDetails.jsp?eventId=<%=eventId%>">View Event Details</a>
							
<%
					 if(past || "Completed".equals(status) || "Inactive".equals(status)){ %>
					<input type="button" class="btn" value="Sign-up closed" disabled>
					<%}else if("Registered".equals(registrationStatus) || "Attended".equals(registrationStatus)){ %>
						<p><strong>You are signed up</strong></p>
					<% } else if("Withdrawn".equals(registrationStatus)){%>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign-up again">
							<input type="hidden" name="registrationId" value="<%=ev.get("regId")%>">
						</form>
					<%}else{%>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign up">
							<input type="hidden" name="eventId" value="<%=eventId%>">
						</form>	
					<%} %>							
					
					</div>
        	
<%				
				}
			if (events.isEmpty() && errorCode.isEmpty()){ 
%>
			    <div class="noResults">
			        <h3>No events found</h3>
			        <p>Try searching with a different keyword or changing your filters.</p>
			    </div>
<%
			} 
%>

		</div>	
		
	<%@ include file="/shared/footer.html" %>
	
	</div>	
	

</body>
</html>