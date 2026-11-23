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
<title>Events Registered</title>
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
	String returnUrl = "registeredEvents.jsp";
	Integer participantId = (Integer) session.getAttribute("userId");

    // Step 2: Load JDBC Driver (optional for newer drivers)
    Class.forName("com.mysql.cj.jdbc.Driver");
    		
    		
    		
	String sql = "{CALL get_participant_registered(?)}";
	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
			CallableStatement cs = conn.prepareCall(sql)){
			cs.setInt(1, participantId);
			
			
			try(ResultSet rs = cs.executeQuery();){
				LocalDate today = LocalDate.now();
				
	//////////////////////start of the html/////////
%>


<div class="page">

<%@ include file="/WEB-INF/shared/header.jsp" %>

<h1> View My sign-ups</h1>

	<div class="card">
	
			<table>
				<tr>
					<th>Event</th>
					<th>Date/Location</th>
					<th>Status</th>
					<th>My Sign up</th>
					<th>Action</th>
				</tr>
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
				<tr>
					<td><%=event_name %></td>
					<td><%=event_date %>/<br><%=location %></td>
					<td><%=status%></td>
					<td><%=registrationStatus%></td>
					<td>
<% 					if("Registered".equals(registrationStatus)){ %>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Withdraw">
							<input type="hidden" name="registrationIdForWithraw" value="<%=registration_id%>">
						</form>
					<% } else if("Withdrawn".equals(registrationStatus)){%>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>" method="post">
							<input type="submit" class="btn btnPrimary" value="Sign-up again">
							<input type="hidden" name="registrationId" value="<%=registration_id%>">
						</form>
					<%} else if(date.isBefore(today) || "Completed".equals(status) || "Canceled".equals(status) || "Attended".equals(registrationStatus)){ %>
						<form action="signup.jsp?returnUrl=<%=returnUrl %>>" method="post">
							<input type="submit" class="btn btnPrimary" value="Withdawal Closed" disabled>
						</form>
					<%}%>
					</td>
				</tr>



<%				}%>


			</table>
	</div>
<jsp:include page="/footer.jsp"/>

</div>
    			
<%			}
		}
	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }

%>


</body>
</html>