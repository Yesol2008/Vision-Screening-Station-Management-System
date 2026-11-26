<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
<%-- fragments kept in WEB-INF so they cannot be opened directly --%>
<%@ include file="/auth/staffGuard.jsp" %>
    
   
<% 
//checking the request method
if (!"POST".equals(request.getMethod())) {
		response.sendRedirect("listEvents.jsp?errCode=invalidRequest");
		return;
}


	String eventId=request.getParameter("eventId");

	int intEventId =0;
//validating the eventId
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
 			
 			//getting the event id, event status and number of participant who has registered
 		String checkSql = "SELECT e.event_id, e.status,"
 				+" COUNT(CASE WHEN r.status != 'Withdrawn' THEN r.participant_id END) AS signup_count "
 				+ "FROM events e "
 				+ "LEFT JOIN registrations r ON e.event_id = r.event_id "
 				+ "WHERE e.event_id = ? "
 				+ "GROUP BY e.event_id, e.status";
 		
 			try(PreparedStatement checkPs = conn.prepareStatement(checkSql)){
 				
 				checkPs.setInt(1, intEventId);
 				
 				try(ResultSet rs = checkPs.executeQuery()){
 					
 					//checking the event
 					//if there is no corresponding event record, it wil return error
 					if (!rs.next()) {
 						response.sendRedirect("listEvents.jsp?errCode=eventNotFound");
 						return;
 						
 					} //if the event status is already inactive, it will also return error
 					else if ("Inactive".equals(rs.getString("status"))) {
 						response.sendRedirect("listEvents.jsp?errCode=alreadyInactive");
 						return;

 					} //if there is a participant who has registered for this event it will also return an error
 					else if (rs.getInt("signup_count") > 0) {
 						response.sendRedirect("listEvents.jsp?errCode=hasSignups");
 						return;

 					}else {
 						// Step 4b: PreparedStatement to deactivate; is_active is kept only in users
 						int event_id = rs.getInt("event_id");
 						try(PreparedStatement ps = conn.prepareStatement("UPDATE events SET status = 'Inactive' WHERE event_id = ?")){
 							
 							ps.setInt(1, event_id);

 	 						// Step 5b: Execute update - returns the number of rows changed
 	 						int rows = ps.executeUpdate();

 	 						// if affected row is more than 0, it will return success msg
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
    