<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ include file="/auth/participantGuard.jsp" %>

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

<%
String eventId=request.getParameter("eventId");

int intEventId =0;

if (eventId != null && eventId.matches("\\d+")) {
	intEventId = Integer.parseInt(eventId);
} else {
	response.sendRedirect("browseEvents.jsp?errCode=invalidEventId");
	return;
}
boolean isRegistered = false;

try {
	
	// Step 1: Load environment variables
	Dotenv dotenv =  Dotenv.configure()
	        .directory(application.getRealPath("/WEB-INF"))
	        .load();;

	String connURL = dotenv.get("DB_URL");
	String username = dotenv.get("DB_USERNAME");
	String password = dotenv.get("DB_PASSWORD");
	String returnUrl = "registeredEvents.jsp";
	Integer participantId = (Integer) session.getAttribute("userId");

    // Step 2: Load JDBC Driver (optional for newer drivers)
    Class.forName("com.mysql.cj.jdbc.Driver");
    		
    		
    		
	String sql = "SELECT * FROM events WHERE event_id =?";
	String sql1 = "SELECT * FROM registrations WHERE participant_id =? AND event_id=? AND status <> 'Withdrawn'";

	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password)){

			PreparedStatement ps = conn.prepareStatement(sql);
			ps.setInt(1, intEventId);
	////////////////////////html start here/////////////////////
%>
	
	<div class="page">
	
<%@ include file="/shared/header.jsp" %>
	
		<div class="card">
	
	
			
<%			try(ResultSet rs = ps.executeQuery()){
				while(rs.next()){
				
					String name = rs.getString("event_name");
					String date = rs.getString("event_date");
					String location = rs.getString("location");
					String status = rs.getString("status");
					String created_at = rs.getString("created_at");
%>					
				<p><strong>Event Name: </strong><%= escapeHtml(name)%></p>
				<p><strong>Event Date: </strong><%=escapeHtml(date) %></p>
				<p><strong>Event Location: </strong><%= escapeHtml(location)%></p>
				<p><strong>Event Status : </strong><%= escapeHtml(status)%></p>
				<p><strong>Event Posted: </strong><%= escapeHtml(created_at)%></p>
					
					
<%				}
			
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
	%>
		<div class="btnGrid">
			<a href="browseEvents.jsp" class="btn btnPrimary">Back</a>
<%		if(!isRegistered){	
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
			
<%		}
    	
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

%>
</body>
</html>