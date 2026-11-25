<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
<%-- fragments kept in WEB-INF so they cannot be opened directly --%>
<%@ include file="/auth/staffGuard.jsp" %>
<%
if (!"POST".equals(request.getMethod())) {
		response.sendRedirect("listEvents.jsp?errCode=invalidRequest");
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

		}catch (NumberFormatException e) {
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
 			
 			//for transaction, turn off the auto commit. It won't affect the db even until we commit the changes by ourself
 			conn.setAutoCommit(false);
 					
 					
			try {
				// delete registrations first
				String sql = "DELETE FROM registrations WHERE event_id = ?";

			try (PreparedStatement ps = conn.prepareStatement(sql)) {
				ps.setInt(1, intEventId);
				ps.executeUpdate();
			}

 	            // After deleting registrations, delete event record
 	            String sql2 = "DELETE FROM events WHERE event_id = ?";

 	            int rows;

 	            try (PreparedStatement ps = conn.prepareStatement(sql2)) {
 	                ps.setInt(1, intEventId);
 	                rows = ps.executeUpdate();
 	            }
			

 	            if (rows == 0) {
 	                conn.rollback();
 	                response.sendRedirect("listEvents.jsp?errCode=eventNotFound");
 	                return;
 	            }

 	            // commit for transaction if the deletion success
 	            conn.commit();

 	            response.sendRedirect("listEvents.jsp?msg=deleted");
 		
			
		} catch (Exception e) {
            conn.rollback();
            throw e;
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