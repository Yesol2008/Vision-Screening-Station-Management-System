<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ include file="/auth/staffGuard.jsp" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Event participants - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
<%

String eventId = request.getParameter("eventId");
int intEventId =0;
		
if (eventId != null && eventId.matches("\\d+")) {
	intEventId = Integer.parseInt(eventId);
} else {
	response.sendRedirect("listEvents.jsp?errCode=invalidEventId");
	return;
}
String eventName = "";
boolean eventFound = false;
List<Map<String, String>> participants = new ArrayList<>();

try {
	
	// Step 1: Load environment variables
	Dotenv dotenv =  Dotenv.configure()
	        .directory(application.getRealPath("/WEB-INF"))
	        .load();

	String connURL = dotenv.get("DB_URL");
	String username = dotenv.get("DB_USERNAME");
	String password = dotenv.get("DB_PASSWORD");

    // Step 2: Load JDBC Driver (optional for newer drivers)
    Class.forName("com.mysql.cj.jdbc.Driver");
    		
	String sql = "{CALL view_event_participants(?)}";
	String sql1 = "SELECT event_name FROM events WHERE event_id=?";
	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password)){
			
			try(PreparedStatement ps = conn.prepareStatement(sql1)){
				ps.setInt(1, intEventId);
					
				try(ResultSet rs1 = ps.executeQuery()){
						
					if(rs1.next()){
						eventFound = true;
						eventName = rs1.getString("event_name");
					}
				}
			}
			
		if(eventFound){
			try(CallableStatement cs = conn.prepareCall(sql)){
		        cs.setInt(1, intEventId);
				try(ResultSet rs = cs.executeQuery();){
					while(rs.next()){
						Map<String, String> p = new HashMap<>();
						p.put("username", rs.getString("username"));
						p.put("participantId", rs.getString("participant_id"));
						p.put("fullName", rs.getString("full_name"));
						p.put("email", rs.getString("email"));
						p.put("phone", rs.getString("contact_number"));
						p.put("status", rs.getString("status"));
						participants.add(p);				
						
					}
					
				}
			}
			
			
		}
	}
} catch (ClassNotFoundException e) {
	application.log("viewEventParticipants.jsp - driver not found", e);
	response.sendRedirect("listEvents.jsp?errCode=dbError");
	return;
} catch (SQLTimeoutException e) {
	application.log("viewEventParticipants.jsp - query timed out", e);
	response.sendRedirect("listEvents.jsp?errCode=dbError");
	return;
} catch (SQLNonTransientConnectionException e) {
	application.log("viewEventParticipants.jsp - cannot connect to database", e);
	response.sendRedirect("listEvents.jsp?errCode=dbError");
	return;
} catch (SQLSyntaxErrorException e) {
	application.log("viewEventParticipants.jsp - bad SQL or missing procedure/column", e);
	response.sendRedirect("listEvents.jsp?errCode=dbError");
	return;
} catch (SQLException e) {                      
	application.log("viewEventParticipants.jsp - SQL error", e);
	response.sendRedirect("listEvents.jsp?errCode=dbError");
	return;
} catch (DotenvException e) {
	application.log("viewEventParticipants.jsp - .env error", e);
	response.sendRedirect("listEvents.jsp?errCode=dbError");
	return;
} catch (NullPointerException e) {              
	application.log("viewEventParticipants.jsp - null value (check .env / DB columns)", e);
	response.sendRedirect("listEvents.jsp?errCode=dbError");
	return;
} catch (Exception e) {                         
	application.log("viewEventParticipants.jsp - unexpected error", e);
	response.sendRedirect("listEvents.jsp?errCode=dbError");
	return;
}		
				
				
if (!eventFound) {
	response.sendRedirect("listEvents.jsp?errCode=eventNotFound");
	return;
}			
boolean hasParticipants = !participants.isEmpty();
				
	//////////////////////start of html/////////////////////////
%>
<div class="page">
	
	<%@ include file="/shared/header.jsp" %>
	
	<div class="card">
			<h2><%= eventName%>: Participant for event</h2>
			<p>Participants who have attended or registered for <%= eventName%></p>
			
<%
				if(hasParticipants){
%>
			<table class="dataTable">
				<tr>
					<th>Participant</th>
					<th>Contact</th>
					<th>Sign up</th>
				</tr>

<%
				for (Map<String, String> p : participants) {
					String user_name = p.get("username");
					String participantId = p.get("participantId");;
				    String fullName = p.get("fullName");
				    String email = p.get("email");
				    String phone = p.get("phone");
				    String status = p.get("status");
	
%>
				<tr>
					<td>
						<p><%=fullName%><br><%=participantId %></p>
					</td>
					<td>
						<p><%= phone%><br><%= email%></p>
					
					</td>
					<td><%= status%></td>
				</tr>

			
<%				}
%>
    		</table>
    		
<%
			}else{
%>				
			<p>No student has registered this event yet</p>
				
<%			}
%>		
		<div>
			<a href="listEvents.jsp" class="btn btnPrimary">Back</a>
		</div>
    </div>
    
	<%@ include file="/shared/footer.html" %>
    
    	
</div>

</body>
</html>