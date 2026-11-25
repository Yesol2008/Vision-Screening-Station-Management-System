<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="io.github.cdimascio.dotenv.DotenvException" %>
<%@ page import="java.time.format.DateTimeParseException" %>
<%@ page import="java.time.LocalDate" %>


<%@ include file="/auth/participantGuard.jsp" %>

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
	.btn:not:(:disabled):hover {
    color: var(--ice);
    background-color: var(--greyLight);
    border-color: var(--grayLight);
	}
	
	</style>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
	
</head>
<body>
<%



String successMsg = request.getParameter("msg");
String errCode = request.getParameter("errCode");

String successMessage ="";
String errorCode ="";

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
}

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
    		
    String returnUrl = "browseEvents.jsp";
    		
    String sql = "{CALL get_events_for_participant(?, ?, ?)}";
    
	Integer participantId = (Integer) session.getAttribute("userId");
	String search = request.getParameter("search");
	String statusFilter = request.getParameter("status");

	if (search != null && search.trim().isEmpty()) {
	    search = null;
	}

	if (statusFilter != null && statusFilter.trim().isEmpty()) {
	    statusFilter = null;
	}

	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
		CallableStatement cs = conn.prepareCall(sql)){
			
			cs.setInt(1, participantId);
			cs.setString(2, search);
		    cs.setString(3, statusFilter);
		    
			try(ResultSet rs = cs.executeQuery();){
			LocalDate today = LocalDate.now();
			boolean hasEvents = false;
				

/////////////////////// start of html page ///////////////////
%>	

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
				while(rs.next()){
					int eventId = rs.getInt("event_id");
					String event_name = rs.getString("event_name");
                    String event_date = rs.getString("event_date");
                    String location = rs.getString("location");
                    String status = rs.getString("status");
					String registrationStatus = rs.getString("registration_status");
                    int registration_id = rs.getInt("registration_id");
    				LocalDate date = LocalDate.parse(event_date);
    				hasEvents = true;

%>
					<div class="eventCard">
					
						<h2><%= escapeHtml(event_name) %></h2>
						<p><strong>Date:</strong> <%= escapeHtml(event_date) %></p>
						<p><strong>Location:</strong> <%= escapeHtml(location) %></p>
						<p><strong>Status:</strong> <%= escapeHtml(status) %></p>
<%
					if("Registered".equals(registrationStatus) || "Attended".equals(registrationStatus)){ %>
						<a href="viewEventDetails.jsp?eventId=<%=eventId%>">View Event Details</a>
						<p><strong>You are signed up</strong></p>
					<% } else if("Withdrawn".equals(registrationStatus)){%>
						<a href="viewEventDetails.jsp?eventId=<%=eventId%>">View Event Details</a>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign-up again">
							<input type="hidden" name="registrationId" value="<%=registration_id%>">
						</form>
					<%} else if(date.isBefore(today) || "Completed".equals(status) || "Inactive".equals(status)){ %>
						<a href="viewEventDetails.jsp?eventId=<%=eventId%>">View Event Details</a>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>>" method="post">
							<input type="submit" class="btn" value="Sign-up closed" disabled>
						</form>
					<%} else{%>
						<a href="viewEventDetails.jsp?eventId=<%=eventId%>">View Event Details</a>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign up">
							<input type="hidden" name="eventId" value="<%=eventId%>">
						</form>	
					<%} %>							
					
					</div>
        	
<%	
					
				}


				if (!hasEvents) {
%>
    				<div class="noResults">
        				<h3>No events found</h3>
        				<p>Try searching with a different keyword or changing your filters.</p>
    				</div>
<%
				}
    			
			}
		} %>
		</div>	
		
	<%@ include file="/shared/footer.html" %>
	
	</div>	
	
		<%
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

</body>
</html>