<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
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
    		
    		
    String sql = "{CALL view_all_events(?, ?)}";
    
    Integer participantId = (Integer) session.getAttribute("userId");
	String search = request.getParameter("search");
	String statusFilter = request.getParameter("status");
	

	if (search != null && search.trim().isEmpty()) {
	    search = null;
	}

	if (statusFilter != null && statusFilter.isEmpty()) {
	    statusFilter = null;
	}

    		
	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
		CallableStatement cs = conn.prepareCall(sql)){

			cs.setString(1, search);
		    cs.setString(2, statusFilter);
			
			try(ResultSet rs = cs.executeQuery();){
		
	///////////////////// start of html pagee/////////////////////
%>

<div class="page">
<%-- placeholder for now will be replaced by shared header include file --%>
	<div class="topbar">
		<a class="brand" href="index.jsp">
			<img class="logo" src="<%= request.getContextPath() %>/images/logo.png" alt="Vision Screening logo">
			<div>
				<div class="brandName">Vision Screening</div>
				<div class="brandSub">Station Management System</div>
			</div>
		</a>
		<nav class="navMenu">
			<a href="">Overview</a>
			<a href="listEvents.jsp" class="active">Events</a>
			<a href="">Participants</a>
		</nav>
		<div class="userBox">
			<span class="userRole">Staff</span>
		</div>
	</div>
	
	
	<h1>Events</h1>
	<div class="card">
	
	<form action="creatEvent.jsp" method="get">
		<input type="submit" value="Create New Event" class="btn btnPrimary">
	</form>
	
		
		<table>
			<tr>
				<th>Event</th>
				<th>Date</th>
				<th>Location</th>
				<th>Status</th>
				<th>Participant</th>
				<th>Action</th>
			
			</tr>
<%				
				while(rs.next()){
					int eventId = rs.getInt("event_id");
					String event_name = rs.getString("event_name");
					String event_date = rs.getString("event_date");
					String location = rs.getString("location");
					String status = rs.getString("status");
					int participants = rs.getInt("participant_count");
                    
                    if(status.equals("Cancelled") || status.equals("Inactive")){
					%>
                    	
			<tr>
				<td><%=event_name %></td>
				<td><%= event_date%></td>
				<td><%= location%></td>
				<td><%=status%></td>
				<td>
					<form action="viewEventParticipants.jsp" method="post">
						<input type="submit" class="btn btnPrimary" value="<%=participants%> signed up">
						<input type="hidden" name="eventId" value="<%=eventId%>">
					</form>
				</td>
				<td>
					<form>
						<input type="submit" class="btn btnPrimary" value="View">
						<input type="submit" class="btn btnPrimary" value="Edit">
						<input type="submit" class="btn btnPrimary" value="Delete">					
					</form>
				</td>
			</tr>
                    	<%
                    }else{
                    
                    %>
                    
            <tr>
				<td><%=event_name %></td>
				<td><%= event_date%></td>
				<td><%= location%></td>
				<td><%=status%></td>
				<td>
					<form action="viewEventParticipants.jsp" method="post">
						<input type="submit" class="btn btnPrimary" value="<%=participants%> signed up">
						<input type="hidden" name="eventId" value="<%=eventId%>">
					</form>
				</td>
				<td>
					<form>
						<input type="submit" class="btn btnPrimary" value="View">
						<input type="submit" class="btn btnPrimary" value="Edit">
						<input type="submit" class="btn btnPrimary" value="Deactivate">
						<input type="submit" class="btn btnPrimary" value="Delete">					
					</form>
				</td>
			</tr>
                    
					
<%				
					}
				}

%>
		</table>

	</div>
	
	<jsp:include page="/footer.jsp"/>
	
</div>


<%
    			
			}
		}
	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }


%>
</body>
</html>