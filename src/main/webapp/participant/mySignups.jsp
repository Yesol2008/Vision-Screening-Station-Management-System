<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="io.github.cdimascio.dotenv.DotenvException" %>
<%@ page import="java.time.format.DateTimeParseException" %>
<%@ page import="java.time.LocalDate" %>

<%@ include file="/WEB-INF/auth/participantGuard.jsp" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Events Registered</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
<%


String successMsg = request.getParameter("msg");
String errCode = request.getParameter("errCode");

String successMessage ="";
String errorCode ="";

if("withdrawn".equals(successMsg)){
	successMessage = "Event Withdrawn Successfully";
}else if("registered".equals(successMsg)){
	successMessage = "Event Registered Successfully";	
}

if("failedWithdrawn".equals(errCode)){
	errorCode = "Failed to withdraw the event";
}else if("failedRegistration".equals(errCode)){
	errorCode = "Faild to register the event";	
}else if("Exception".equals(errCode)){
	errorCode ="Unable to connect to the server for signup/withdrawal. Please try again later.";
}

try {
	
	// Step 1: Load environment variables
	Dotenv dotenv =  Dotenv.configure()
	        .directory(application.getRealPath("/WEB-INF"))
	        .load();;

	String connURL = dotenv.get("DB_URL");
	String username = dotenv.get("DB_USERNAME");
	String password = dotenv.get("DB_PASSWORD");
	String returnUrl = "mySignups.jsp";
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
			<% if (!successMessage.isEmpty()) { %>
    			<p class="msgBox msgSuccess"><%= successMessage %></p>
			<% } %>
			<% if (!errorCode.isEmpty()) { %>
    			<p class="msgBox msgError"><%= errorCode %></p>
			<% } %>
	
	
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
	<%@ include file="/WEB-INF/shared/footer.html" %>

</div>
    			
<%			}
		}
	} catch (SQLException e) {
		System.err.println("Database error in mySignups.jsp"+ e);
	    errorCode="Unable to connect to the server. Please try again later.";
	} catch (DotenvException e) {
		System.err.println("Environment configuration error in mySignups.jsp"+ e);
		errorCode="Something went wrong. Please try again later.";


	} catch (DateTimeParseException e) {
		System.err.println("Invalid event date format in mySignups.jsp"+ e);
		errorCode = "Unable to display event information. Please try again later.";

	}catch (Exception e) {
        e.printStackTrace();
        System.err.println("Database connection error"+ e);
        out.println("Unable to connect to the database.");
    }

%>


</body>
</html>