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
String eventId=request.getParameter("eventId");

int intEventId =0;

if (eventId != null && eventId.matches("\\d+")) {
	intEventId = Integer.parseInt(eventId);
} else {
	response.sendRedirect("listEvents.jsp?errCode=invalidEventId");
	return;
}

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
	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password)){

			PreparedStatement ps = conn.prepareStatement(sql);
			ps.setInt(1, intEventId);
	////////////////////////html start here/////////////////////
%>
	
	<div class="page">
	
	<%@ include file="/WEB-INF/shared/header.jsp" %>
	
		<div class="card">
	
	
			
<%			try(ResultSet rs = ps.executeQuery()){
				while(rs.next()){
				
					String name = rs.getString("event_name");
					String date = rs.getString("event_date");
					String location = rs.getString("location");
					String status = rs.getString("status");
					String created_at = rs.getString("created_at");
%>					
				<p><strong>Event Name: </strong><%= name%></p>
				<p><strong>Event Date: </strong><%=date %></p>
				<p><strong>Event Location: </strong><%= location%></p>
				<p><strong>Event Status : </strong><%= status%></p>
				<p><strong>Event Posted:</strong><%= created_at%></p>
					
					
<%				}
			
			}%>
			<a href="listEvents.jsp" class="btn btnPrimary">Back</a>
		</div>
			<%@ include file="/WEB-INF/shared/footer.html" %>
		
	
	</div>	
			
<%		}
    	
	}catch (Exception e) {
    e.printStackTrace();
    application.log("Database connection error", e);
    out.println("Unable to connect to the database.");
	}

%>
</body>
</html>