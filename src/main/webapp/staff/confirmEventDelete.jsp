<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
    
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

if (!"POST".equals(request.getMethod())) {
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
	        .load();;

	String connURL = dotenv.get("DB_URL");
	String username = dotenv.get("DB_USERNAME");
	String password = dotenv.get("DB_PASSWORD");

    // Step 2: Load JDBC Driver (optional for newer drivers)
    Class.forName("com.mysql.cj.jdbc.Driver");
    boolean isRegistered=false;
    int count = 0;
    String isRegisteredMsg="";
    	 
    	
    		
 // Step 3: Establish database connection. Used try-with so that connection will close automatically
 		try(Connection conn = DriverManager.getConnection(connURL, username, password)){
 			String sql="SELECT COUNT(*) AS registrationCount FROM registrations WHERE event_id=?";
 			////////////////////start of html////////////////////////////////
 			
 		// Step 4: Create Statement object
 	 		try(PreparedStatement ps = conn.prepareStatement(sql)){
 	 				ps.setInt(1, intEventId);
 	 			
 	 			try(ResultSet rs = ps.executeQuery()){
 	 				
 	 	 			if(rs.next()){
 	 	 				count = rs.getInt("registrationCount");
 	 	 			}	
 	 	 			if(count>0){
 	 	 				isRegistered = true;		
 	 	 			}
 	 			}
 	 		}
 			

 	 		if(isRegistered){
 	 			isRegisteredMsg = count + " participant(s) have registered for this event. By deleting this event, you will delete the registration records aswell.";
 	 		}else{
 	 			isRegisteredMsg = "By deleting this event, you will delete the registration records aswell.";
 	 		}
 		}
 


%>
<div class="page">
<%@ include file="/WEB-INF/shared/header.jsp" %>


	<div class="card">
	

		<h1>Delete Event</h1>
		<p class="msgBox msgError"><%=isRegisteredMsg%></p>
		<form method="post" action="deleteEvent.jsp">
 			<input type="submit" class="btn btnPrimary" value="Delete">
 			<input type="hidden" name="eventId" value="<%=intEventId%>">
 			 <a href="listEvents.jsp" class="btn btnPrimary">Back</a>
 			
 		</form>
 
	</div>
	
		<%@ include file="/WEB-INF/shared/footer.html" %>
	

</div>
<%
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
    e.printStackTrace();
    application.log("Database connection error", e);
    out.println("Unable to connect to the database.");
}


%>
</body>
</html>