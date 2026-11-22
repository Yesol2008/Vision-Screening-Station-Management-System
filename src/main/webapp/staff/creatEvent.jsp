<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ include file="/WEB-INF/auth/staffGuard.jsp" %>
<%!
private String escapeHtml(String input) {
    if (input == null) {
        return "";
    }

    return input.replace("&", "&amp;")
                .replace("<", "&lt;")
             	.replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
}
%>

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
}

// Event date validation
if (eventDate == null || eventDate.trim().isEmpty()) {
	eventDateErr = "Event date cannot be empty.";
}

// Event location validation
if (eventLocation == null || eventLocation.trim().isEmpty()) {
	eventLocationErr = "Event location cannot be empty.";
}

// Status validation
if (status == null || status.trim().isEmpty()) {
	statusErr = "Please select an event status.";
}

	// Only insert if there are no validation errors
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
    		
    		
	String sql = "INSERT INTO events (event_name, event_date, location, status) VALUES (?,?,?,?)";

    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
		PreparedStatement ps = conn.prepareStatement(sql)){
			ps.setString(1, eventName);
			ps.setString(2, eventDate);
			ps.setString(3, eventLocation);
			ps.setString(4, status);
			
			ps.executeUpdate();
			
				
		}
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
<%-- placeholder for now will be replaced by shared header include file --%>
	<div class="topbar">
		<a class="brand" href="index.jsp">
			<img class="logo" src="<%= request.getContextPath() %>/images/logo.png" alt="Vision Screening logo">
			<div>
				<div class="brandName">Vision Screening</div>
				<div class="brandSub">Station Management System</div>
			</div>
		</a>
		<nav class="navMenu">
			<a href="">Overview</a>
			<a href="listEvents.jsp" class="active">Events</a>
			<a href="">Participants</a>
		</nav>
		<div class="userBox">
			<span class="userRole">Staff</span>
		</div>
	</div>
	
	<div class="card">
	<h1>Create Event</h1>
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
	
	
	
</div>
</body>
</html>