<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ include file="/auth/participantGuard.jsp" %>
<%
//getting event id
String eventId=request.getParameter("eventId");

int intEventId =0;
//validating event id
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

//to check if the user has already registered for this event, or the event is already found
boolean isRegistered = false;
boolean found = false;
Integer participantId = (Integer) session.getAttribute("userId");


//declaring values that will be displayed on te html
String name = "";
String date = "";
String location = "";
String status = "";
String created_at = "";


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
    		
    		
    		
	String sql = "SELECT * FROM events WHERE event_id =?";
	String sql1 = "SELECT * FROM registrations WHERE participant_id =? AND event_id=? AND status <> 'Withdrawn'";

	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password)){

			PreparedStatement ps = conn.prepareStatement(sql);
			ps.setInt(1, intEventId);
			
			try(ResultSet rs = ps.executeQuery()){
				while(rs.next()){
                    found = true;
					name = rs.getString("event_name");
					date = rs.getString("event_date");
					location = rs.getString("location");
					status = rs.getString("status");
					created_at = rs.getString("created_at");
				}
			}
			
		
		if (participantId != null) {
			try (PreparedStatement ps1 = conn.prepareStatement(sql1)) {
				ps1.setInt(1, participantId);
				ps1.setInt(2, intEventId);
				try (ResultSet rs1 = ps1.executeQuery()) {
					isRegistered = rs1.next();   // true if a row exists
				}
			}
		}
	}
} catch (ClassNotFoundException e) {
	System.err.println("confirmEventDeactivate.jsp - driver not found: " + e);
	response.sendRedirect("browseEvents.jsp?errCode=dbError");
	return;
} catch (SQLException e) {
	System.err.println("confirmEventDeactivate.jsp - SQL error: " + e);
	response.sendRedirect("browseEvents.jsp?errCode=dbError");
	return;
} catch (DotenvException e) {
	System.err.println("confirmEventDeactivate.jsp - .env error: " + e);
	response.sendRedirect("browseEvents.jsp?errCode=dbError");
	return;
}catch (Exception e) {
e.printStackTrace();
application.log("Database connection error", e);
out.println("Unable to connect to the database.");
}

if(!found){
	response.sendRedirect("browseEvents.jsp?errCode=invalidEventId");
}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Event detail - Vision Screening</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
<style>
.btnGrid {
	display: grid;
	grid-template-columns: 1fr 2fr;
	gap: 8px;
	width: 40%;
	}

	.btnGrid form {
	margin: 0;
	}

	.btnGrid .btn {
	display: block;
	width: 100%;
	padding: 8px 10px;
	text-align: center;
	align-items: center;  
	}

</style>
</head>
<body>
	
	<div class="page">
	
<%@ include file="/shared/header.jsp" %>
	
		<div class="card">
	
					
				<p><strong>Event Name: </strong><%= escapeHtml(name)%></p>
				<p><strong>Event Date: </strong><%=escapeHtml(date) %></p>
				<p><strong>Event Location: </strong><%= escapeHtml(location)%></p>
				<p><strong>Event Status : </strong><%= escapeHtml(status)%></p>
				<p><strong>Event Posted: </strong><%= escapeHtml(created_at)%></p>
					
					

		<div class="btnGrid">
			<a href="browseEvents.jsp" class="btn btnPrimary">Back</a>
<%		if(!isRegistered && !"Inactive".equals(status)&& !"Completed".equals(status)){	
 %>
			<form action="signup.jsp?returnUrl=mySignups.jsp" method="post">
				<input type="submit" class="btn btnPrimary" value="Sign up">
				<input type="hidden" name="eventId" value="<%=eventId%>">
			</form>	
		
<%
		}else{
%>
			<a href="mySignups.jsp" class="btn btnPrimary">Manage Your Registrations</a>
<%			
		}
%>
		</div>
		</div>
		
	<%@ include file="/shared/footer.html" %>
	
	</div>	
</body>
</html>