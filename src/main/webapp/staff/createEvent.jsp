<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeParseException" %>

<%@ include file="/WEB-INF/auth/staffGuard.jsp" %>


<%

String message = "";

String eventNameErr = null;
String eventDateErr = null;
String eventLocationErr = null;
String statusErr = null;

String eventName = request.getParameter("event_name");
String eventDate = request.getParameter("event_date");
String eventLocation = request.getParameter("event_location");
String status = request.getParameter("status");


if ("POST".equalsIgnoreCase(request.getMethod())) {
// Event name validation
if (eventName == null || eventName.trim().isEmpty()) {
	eventNameErr = "Event name cannot be empty.";
}else if (!eventName.matches("[A-Za-z '\\-]{2,100}")) {
	eventNameErr = "Use 2-100 letters. Spaces, hyphens and apostrophes are allowed.";
}

// Event date validation
if (eventDate == null || eventDate.trim().isEmpty()) {
	eventDateErr = "Event date cannot be empty.";
}else {
	try {
		LocalDate.parse(eventDate);
	} catch (DateTimeParseException e) {
		eventDateErr = "Please enter a valid event date.";
	}
}

// Event location validation
if (eventLocation == null || eventLocation.trim().isEmpty()) {
	eventLocationErr = "Event location cannot be empty.";
}else if (!eventLocation.matches("[A-Za-z0-9][A-Za-z ,.'\\-#]{1,99}")) {
	eventLocationErr = "Only letters, digits, spaces, hyphens, dots, '#', and apostrophes are allowed.";
}


// Status validation
if (status == null || status.trim().isEmpty()) {
	statusErr = "Please select an event status.";
}else if (!status.equals("Upcoming") &&!status.equals("Completed") &&!status.equals("Ongoing")) {
	statusErr = "Invalid event status.";
}

	// Only insert if theres no validation errors
	if (eventNameErr == null && eventDateErr == null &&
	eventLocationErr == null && statusErr == null) {
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
    		
    	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password)){
			
			String sql2 ="SELECT event_name FROM events WHERE event_name = ?";

			 boolean eventExists = false;
			 
			try (PreparedStatement checkPs = conn.prepareStatement(sql2)) {
				checkPs.setString(1, eventName.trim());

					try (ResultSet rs = checkPs.executeQuery()) {
						if (rs.next()) {
							eventExists = true;
							}
					}
			}
			
			
			if (eventExists) {
				
				message = "This event already exists.";

			}else{
				
				String sql = "INSERT INTO events (event_name, event_date, location, status) VALUES (?,?,?,?)";

				try(PreparedStatement ps = conn.prepareStatement(sql)){
					ps.setString(1, eventName.trim());
					ps.setString(2, eventDate);
					ps.setString(3, eventLocation.trim());
					ps.setString(4, status);
					
					ps.executeUpdate();
					
					
				}
				
				response.sendRedirect("listEvents.jsp?msg=successCreate");
				return;
			}
			
		
		}
	} catch (ClassNotFoundException e) {
		System.err.println("confirmEventDeactivate.jsp - driver not found: " + e);
		response.sendRedirect("listEvents.jsp?errCode=dbError");
		return;
	} catch (SQLException e) {
		System.err.println("confirmEventDeactivate.jsp - SQL error: " + e);
		response.sendRedirect("listEvents.jsp?errCode=dbError");
		return;
	} catch (DotenvException e) {
		System.err.println("confirmEventDeactivate.jsp - .env error: " + e);
		response.sendRedirect("listEvents.jsp?errCode=dbError");
		return;
	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }
	
	
}
}


%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
<div class="page">
<%@ include file="/WEB-INF/shared/header.jsp" %>

	<div class="card">
	<h1>Create Event</h1>
		<% if (!message.isEmpty()) { %>
    		<p class="msgBox msgError"><%= message %></p>
		<% } %>
		<form class="formGrid" method="post">
			<div class="field">
				<label>Event Name :<span class="req">*</span> </label>
				<input type="text" name="event_name" 
				value="<%=eventName == null ? "" : escapeHtml(eventName.trim()) %>" 
				class="<%=eventNameErr != null ? "inputError" : "" %>">
				<% if (eventNameErr != null) { %>
					<div class="fieldError"><%= escapeHtml(eventNameErr) %></div>
				<% } %>
			</div>
			<div class="field">
				<label>Event Date :<span class="req">*</span></label>
				<input type="date" name="event_date" 
				value="<%= eventDate == null ? "" : escapeHtml(eventDate) %>"
				class="<%= eventDateErr != null ? "inputError" : "" %>">
				<% if (eventDateErr != null) { %>
					<div class="fieldError"><%= escapeHtml(eventDateErr) %></div>
				<% } %>
				
			</div>
			
			<div class="field">
				<label>Event Location :<span class="req">*</span></label>
				<input type="text" name="event_location" 
				value="<%= eventLocation == null ? "" : escapeHtml(eventLocation.trim()) %>"
				class="<%= eventLocationErr != null ? "inputError" : "" %>">
				<% if (eventLocationErr != null) { %>
					<div class="fieldError"><%= escapeHtml(eventLocationErr) %></div>
				<% } %>
			</div>
			<div class="field">
				<label>Status :<span class="req">*</span></label>
				<select name="status" class="grid">
					<option value="">Select Statuses</option>
					<option value="Upcoming" <%= "Upcoming".equals(status) ? "selected" : "" %>>
					Upcoming</option>
					<option value="Completed" <%= "Completed".equals(status) ? "selected" : "" %>>
					Completed </option>
					<option value="Ongoing" <%= "Ongoing".equals(status) ? "selected" : "" %>>
					Ongoing</option>
				</select>
				<% if (statusErr != null) { %>
        			<div class="fieldError"><%= escapeHtml(statusErr) %></div>
    			<% } %>
			</div>
			<div class="formActions">
				<input type="submit" value="submit" class="btn btnPrimary">
				<a href="listEvents.jsp" class="btn btnPrimary">Back</a>
				
			</div>
			
			
			
		</form>
		
	
	</div>
	
	
	<%@ include file="/footer.html" %>
	
</div>
</body>
</html>