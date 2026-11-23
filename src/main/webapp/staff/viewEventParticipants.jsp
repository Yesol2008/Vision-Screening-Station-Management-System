<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
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
    		
	String eventId = request.getParameter("eventId");
    int intEventId =0;
    		
    if (eventId != null && eventId.matches("\\d+")) {
		intEventId = Integer.parseInt(eventId);
	} else {
		response.sendRedirect("listEvents.jsp?errCode=invalidEventId");
		return;
    }
    		
	String sql = "{CALL view_event_participants(?)}";
	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
		CallableStatement cs = conn.prepareCall(sql)){
	        cs.setInt(1, intEventId);
			try(ResultSet rs = cs.executeQuery();){
				boolean hasParticipants = rs.next();
				
				String sql1 = "SELECT event_name FROM events WHERE event_id=?";
				
				
				try(PreparedStatement ps = conn.prepareStatement(sql1)){
					ps.setInt(1, intEventId);
				
					
					
					try(ResultSet rs1 = ps.executeQuery()){
						
						if(rs1.next()){
					
					String eventName = rs1.getString("event_name");
				
	//////////////////////start of html/////////////////////////
%>
<div class="page">
	
	<%@ include file="/WEB-INF/shared/header.jsp" %>
	
	<div class="card">
			<h2><%= eventName%>: Participant for event</h2>
			<p>Participants who have attended or registered for <%= eventName%></p>
			
<%
						} else {
						    response.sendRedirect("listEvents.jsp?errCode=eventNotFound");
						    return;
						}
					}
				}
				if(hasParticipants){

%>
			<table>
				<tr>
					<th>Participant</th>
					<th>Contact</th>
					<th>Sign up</th>
				</tr>

<%
				do{
					hasParticipants = true;
					String user_name = rs.getString("username");
					String participantId = rs.getString("participant_id");
				    String fullName = rs.getString("full_name");
				    String email = rs.getString("email");
				    String phone = rs.getString("contact_number");
				    String status = rs.getString("status");
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

			
<%				}while(rs.next());

%>
    		</table>
    		
<%
			}else{
%>				
			<p>No student has registered this event yet</p>
				
<%			}
%>	
		<a href="listEvents.jsp" class="btn btnPrimary">Back</a>
    </div>
    
	<%@ include file="/WEB-INF/shared/footer.html" %>
    
    	
</div>
    			
<%			
				
			}
		}
	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }


%>
</body>
</html>