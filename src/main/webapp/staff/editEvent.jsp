<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeParseException" %>

<%@ include file="/WEB-INF/auth/staffGuard.jsp" %>



<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
<%
String eventId=request.getParameter("eventId");

int intEventId =0;

if (eventId != null && eventId.matches("\\d+")) {

	try {
		intEventId = Integer.parseInt(eventId);

		if (intEventId <= 0) {
			response.sendRedirect("listEvents.jsp?errCode=invalidEventId");
			return;
		}

	} catch (NumberFormatException e) {
		response.sendRedirect("listEvents.jsp?errCode=invalidEventId");
		return;
	}

} else {
	response.sendRedirect("listEvents.jsp?errCode=invalidEventId");
	return;
}


String eventNameErr = null;
String eventDateErr = null;
String eventLocationErr = null;
String statusErr = null;

boolean isPost = "POST".equalsIgnoreCase(request.getMethod());

String eventName = request.getParameter("event_name");
String eventDate = request.getParameter("event_date");
String eventLocation = request.getParameter("event_location");
String status = request.getParameter("status");

if (isPost) {

	// Event name validation
	if (eventName == null || eventName.trim().isEmpty()) {
		eventNameErr = "Event name cannot be empty.";

	} else if (!eventName.trim().matches("[A-Za-z '\\-]{2,100}")) {
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

	} else if (!eventLocation.matches("[A-Za-z0-9][A-Za-z ,.'\\-#]{1,99}")) {
		eventLocationErr = "Only letters, digits, spaces, hyphens, dots, '#', and apostrophes are allowed.";
	}

	// Status validation
	if (status == null || status.trim().isEmpty()) {
		statusErr = "Please select an event status.";
	}else if (!status.equals("Upcoming") &&!status.equals("Completed") &&!status.equals("Ongoing")) {
		statusErr = "Invalid event status.";
	}
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
    		
    		
	
		// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password)){

			
			if (isPost && eventNameErr == null && eventDateErr == null &&
				eventLocationErr == null && statusErr == null) {

				String sql1 = "UPDATE events SET event_name = ?, event_date = ?, location = ?, status = ? WHERE event_id = ?";

				try (PreparedStatement ps1 = conn.prepareStatement(sql1)) {

					ps1.setString(1, eventName.trim());
					ps1.setString(2, eventDate);
					ps1.setString(3, eventLocation.trim());
					ps1.setString(4, status);
					ps1.setInt(5, intEventId);

					int rowsUpdated = ps1.executeUpdate();

					if (rowsUpdated > 0) {
						response.sendRedirect("listEvents.jsp?msg=successUpdate");
							return;
					}
				}
			}
			
			String sql = "SELECT * FROM events WHERE event_id = ?";

			try (PreparedStatement ps = conn.prepareStatement(sql)) {

				ps.setInt(1, intEventId);

				try (ResultSet rs = ps.executeQuery()) {
	//////////////// start of html//////////////
%>
			    	
		<div class="page">
		
		<%@ include file="/WEB-INF/shared/header.jsp" %>
		
			<div class="card">
			    	
			    	
				<form class="formGrid" method="post">
			    		
<%	
					if (rs.next()) {
						
						int event_id = rs.getInt("event_id");
						String name = rs.getString("event_name");
			        	String date = rs.getString("event_date");
			       		String location = rs.getString("location");
			       		String eventStatus = rs.getString("status");

			       ////////////html/////////////////
%>					
					<div class="field">
						<label>Event Name :<span class="req">*</span> </label>
						<input type="text" name="event_name" 
						value="<%= escapeHtml(name) %>"
						class="<%=eventNameErr != null ? "inputError" : "" %>">
						<% if (eventNameErr != null) { %>
							<div class="fieldError"><%= escapeHtml(eventNameErr) %></div>
						<% } %>
					</div>
					<div class="field">
						<label>Event Date :<span class="req">*</span></label>
						<input type="date" name="event_date" 
						value="<%= escapeHtml(date) %>"
						class="<%= eventDateErr != null ? "inputError" : "" %>">
						<% if (eventDateErr != null) { %>
							<div class="fieldError"><%= escapeHtml(eventDateErr) %></div>
						<% } %>
						
					</div>
					
					<div class="field">
						<label>Event Location :<span class="req">*</span></label>
						<input type="text" name="event_location" 
						value="<%= escapeHtml(location) %>"
						class="<%= eventLocationErr != null ? "inputError" : "" %>">
						<% if (eventLocationErr != null) { %>
							<div class="fieldError"><%= escapeHtml(eventLocationErr) %></div>
						<% } %>
					</div>
					<div class="field">
						<label>Status :<span class="req">*</span></label>
						<select name="status" class="grid">
							<option value="">Select Statuses</option>
							<option value="Upcoming"<%= "Upcoming".equals(eventStatus) ? "selected" : "" %>>
							Upcoming</option>
							<option value="Completed"<%= "Completed".equals(eventStatus) ? "selected" : "" %>>
							Completed </option>
							<option value="Ongoing"<%= "Ongoing".equals(eventStatus) ? "selected" : "" %>>
							Ongoing</option>
						</select>
						<% if (statusErr != null) { %>
		        			<div class="fieldError"><%= escapeHtml(statusErr) %></div>
		    			<% } %>
					</div>
					<div class="formActions">
						<input type="submit" value="submit" class="btn btnPrimary">
						<input type="hidden" name="eventId" value="<%=event_id%>">
						<a href="listEvents.jsp" class="btn btnPrimary">Back</a>
					</div>
<%

				} else {
					response.sendRedirect("listEvents.jsp?errCode=eventNotFound");
					return;
				}
			}
		}

		
		}%>

		</form>
		</div>
		
	<%@ include file="/WEB-INF/shared/footer.html" %>
		
	
	</div>	
			
<%			
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
		System.err.println("Database connection error"+ e);
	    response.sendRedirect("listEvents.jsp?errCode=dbError");
	}


%>
</body>
</html>