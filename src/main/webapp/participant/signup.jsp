<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    <%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%@ include file="/auth/participantGuard.jsp" %>

<%

String returnUrl = request.getParameter("returnUrl");

if (returnUrl == null || returnUrl.isEmpty()) {
    returnUrl = "browseEvents.jsp";
}
try {
	Integer participantId = (Integer) session.getAttribute("userId");
	
	if(participantId == null){
		response.sendRedirect("login.jsp");
		return;
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
		String registrationIdForWithraw = request.getParameter("registrationIdForWithraw");
		
		//to make sure that there's only one parameter provided.
		int actionCount = 0;

		if (registrationId != null && !registrationId.trim().isEmpty()) {
			actionCount++;
		}

	 	if (eventId != null && !eventId.trim().isEmpty()) {
			actionCount++;
	 	}

	 	if (registrationIdForWithraw != null &&
			!registrationIdForWithraw.trim().isEmpty()) {
			actionCount++;
		}
		
	 	//redirected to previous page when there's no exactly 1 parameter
		if (actionCount != 1) {
			response.sendRedirect(returnUrl+"?errCode=InvalidRequest");
			return;
		}
	 	
	 	
		int id;

		if (registrationId != null && !registrationId.trim().isEmpty()) {
			id = Integer.parseInt(registrationId.trim());
		} else if (eventId != null && !eventId.trim().isEmpty()) {
			id = Integer.parseInt(eventId.trim());
		} else {
			id = Integer.parseInt(registrationIdForWithraw.trim());
		}

		if (id <= 0) {
			response.sendRedirect(returnUrl + "?errCode=InvalidRequest");
			return;
		}

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
					response.sendRedirect(returnUrl+"?errCode=failedRegistration");
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
					response.sendRedirect(returnUrl+"?msg=registered");
					return;
				}else{
					response.sendRedirect(returnUrl+"?errCode=failedRegistration");
					return;
				}
			}
			
			
		}else if(registrationIdForWithraw != null && !registrationIdForWithraw.isEmpty()){
			String sql ="UPDATE registrations SET status = 'Withdrawn' " +
					"WHERE registration_id = ? " +
            	    "AND participant_id = ? " +
            	    "AND status = 'Registered'";
			
			try(PreparedStatement ps = conn.prepareStatement(sql)){
				
				ps.setInt(1, Integer.parseInt(registrationIdForWithraw));
				ps.setInt(2, participantId);
				
				int rowsUpdated = ps.executeUpdate();
				
				if(rowsUpdated > 0){
					response.sendRedirect(returnUrl+"?msg=withdrawn");
					return;
				}else{
					response.sendRedirect(returnUrl+"?errCode=failedWithdrawn");
					return;
				}
				
			}
			
			
		}else{
			response.sendRedirect(returnUrl+"?errCode=failedRegistration");
			return;
		}
		
		
			
			
		}
	} catch (ClassNotFoundException e) {
		System.err.println("JDBC Driver not found"+ e);
		response.sendRedirect(returnUrl+"?errCode=Exception");
		return;

	} catch (SQLException e) {
		System.err.println("Database error in login.jsp"+ e);
		response.sendRedirect(returnUrl+"?errCode=Exception");
		return;
	}catch (Exception e) {
        e.printStackTrace();
        System.err.println("Database connection error"+ e);
		response.sendRedirect(returnUrl+"?errCode=Exception");
        return;
    }


%>