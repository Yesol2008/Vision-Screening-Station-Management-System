<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    <%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%@ include file="/WEB-INF/auth/participantGuard.jsp" %>

<%
try {
	Integer participantId = (Integer) session.getAttribute("userId");
	
	if(participantId == null){
		response.sendRedirect("login.jsp");
		return;
	}
	
	String returnUrl = request.getParameter("returnUrl");

    if (returnUrl == null || returnUrl.isEmpty()) {
        returnUrl = "browseEvents.jsp";
    }
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
		
		
				
		String registrationId = request.getParameter("registrationId");
		String eventId = request.getParameter("eventId");

		if(registrationId != null && !registrationId.isEmpty()){
			
			String sql ="UPDATE registrations SET status = 'Registered' " +
						"WHERE registration_id = ? " +
                	    "AND participant_id = ? " +
                	    "AND status = 'Withdrawn'";
			
			try(PreparedStatement ps = conn.prepareStatement(sql)){
				
				ps.setInt(1, Integer.parseInt(registrationId));
				ps.setInt(2, participantId);
				
				int rowsUpdated = ps.executeUpdate();
				
				if(rowsUpdated > 0){
					response.sendRedirect(returnUrl+"?msg=registered");
					return;
				}else{
					response.sendRedirect(returnUrl+ "?msg=failedRegistration");
					return;
				}
				
			}
			
		}else if(eventId != null && !eventId.isEmpty()){
			
			String sql ="INSERT INTO registrations (participant_id, event_id, status) " +
						"VALUES (?, ?, 'Registered')";
			
			try(PreparedStatement ps = conn.prepareStatement(sql)){
				
				ps.setInt(1, participantId);
				ps.setInt(2, Integer.parseInt(eventId));
				
				int rowsInserted = ps.executeUpdate();
				
				if (rowsInserted > 0) {
					response.sendRedirect(returnUrl+ "?msg=registered");
					return;
				}else{
					response.sendRedirect(returnUrl+"?msg=failedRegistration");
					return;
				}
			}
			
			
		}else{
			response.sendRedirect(returnUrl+"?msg=failedRegistration");
			return;
		}
		
		
			
			
		}
	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        
    }


%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

</body>
</html>