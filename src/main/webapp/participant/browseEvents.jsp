<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ include file="/WEB-INF/auth/participantGuard.jsp" %>
<%@ page import="java.time.LocalDate" %>


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
	        .load();;

	String connURL = dotenv.get("DB_URL");
	String username = dotenv.get("DB_USERNAME");
	String password = dotenv.get("DB_PASSWORD");

    // Step 2: Load JDBC Driver (optional for newer drivers)
    Class.forName("com.mysql.cj.jdbc.Driver");
    		
    String returnUrl = "browseEvents.jsp";
    		
	String sql = "{CALL get_events_for_participant(?)}";
	Integer participantId = (Integer) session.getAttribute("userId");

	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
		CallableStatement cs = conn.prepareCall(sql)){
			
			cs.setInt(1, participantId);
			try(ResultSet rs = cs.executeQuery();){
							    LocalDate today = LocalDate.now();
				

/////////////////////// start of html page ///////////////////
%>	

<div class="page">
<h1>Browse Events</h1>

	
			
			
			
			
		<div class="card">
<%			
				while(rs.next()){
					int eventId = rs.getInt("event_id");
					String event_name = rs.getString("event_name");
                    String event_date = rs.getString("event_date");
                    String location = rs.getString("location");
                    String status = rs.getString("status");
					String registrationStatus = rs.getString("registration_status");
                    int registration_id = rs.getInt("registration_id");
    				LocalDate date = LocalDate.parse(event_date);

%>
					<div class="eventCard">
					
						<h2><%= event_name %></h2>
						<p><strong>Date:</strong> <%= event_date %></p>
						<p><strong>Location:</strong> <%= location %></p>
						<p><strong>Status:</strong> <%= status %></p>
<%
					if("Registered".equals(registrationStatus) || "Attended".equals(registrationStatus)){ %>
						<p><strong>You are signed up</strong></p>
					<% } else if("Withrawn".equals(registrationStatus)){%>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign-up again">
							<input type="hidden" name="registrationId" value="<%=registration_id%>">
						</form>
					<%} else if(date.isBefore(today) || "Completed".equals(status)){ %>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign-up closed" disabled>
						</form>
					<%} else{%>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign up">
							<input type="hidden" name="eventId" value="<%=eventId%>">
						</form>	
					<%} %>							
					
					</div>
        	
<%	
					
				}
    			
			}
		} %>
		</div>	
		
		<jsp:include page="/footer.jsp"/>
	
	</div>	
	
		<%
	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }

%>

</body>
</html>