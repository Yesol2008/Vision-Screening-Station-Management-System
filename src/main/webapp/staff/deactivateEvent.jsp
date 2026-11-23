<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
<%-- fragments kept in WEB-INF so they cannot be opened directly --%>
<%@ include file="/WEB-INF/auth/staffGuard.jsp" %>
    
   
<%if (!"POST".equals(request.getMethod())) {
		response.sendRedirect("listEvents.jsp?errCode=InvalidRequest");
		return;
	}


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
    	
    		
 // Step 3: Establish database connection. Used try-with so that connection will close automatically
 		try(Connection conn = DriverManager.getConnection(connURL, username, password)){
 			
 			
 		String checkSql = "SELECT e.event_id, e.status, COUNT(r.participant_id) AS signup_count "
 				+ "FROM events e "
 				+ "LEFT JOIN registrations r ON e.event_id = r.event_id "
 				+ "WHERE e.event_id = ? "
 				+ "GROUP BY e.event_id, e.status";
 		
 			try(PreparedStatement checkPs = conn.prepareStatement(checkSql)){
 				
 				checkPs.setInt(1, intEventId);
 				
 				try(ResultSet rs = checkPs.executeQuery()){
 					
 					
 					if (!rs.next()) {
 						response.sendRedirect("listEvents.jsp?errCode=eventNotFound");
 						return;
 						
 					} else if ("Inactive".equals(rs.getString("status"))||"Cancelled".equals(rs.getString("status"))) {
 						response.sendRedirect("listEvents.jsp?errCode=alreadyInactive");
 						return;

 					} else if (rs.getInt("signup_count") > 0) {
 						response.sendRedirect("listEvents.jsp?errCode=hasSignups");
 						return;

 					}else {
 						// Step 4b: PreparedStatement to deactivate; is_active is kept only in users
 						int event_id = rs.getInt("event_id");
 						try(PreparedStatement ps = conn.prepareStatement("UPDATE events SET status = 'Inactive' WHERE event_id = ?")){
 							
 							ps.setInt(1, event_id);

 	 						// Step 5b: Execute update - returns the number of rows changed
 	 						int rows = ps.executeUpdate();

 	 						// Step 6b: Process result
 	 						if (rows > 0) {
 	 	 						response.sendRedirect("listEvents.jsp?msg=deactivated");
 	 	 						return;

 	 						} else {
 	 	 						response.sendRedirect("listEvents.jsp?errCode=eventNotFound");
 	 	 						return;

 	 						}
 							
 						}
 						
 					}
 				}
 				
 			}
 					

 		}
}catch (Exception e) {
	e.printStackTrace();
	application.log("Database connection error", e);
	out.println("Unable to connect to the database.");
}

%>
    