<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%@ include file="/WEB-INF/auth/staffGuard.jsp" %>
<%@ include file="/WEB-INF/shared/helpers.jsp" %>


<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
<style>

	.searchBar{
	display: grid;
    grid-template-columns: 6fr 2fr 1fr;;
    gap: 20px;
    padding: 20px;
	}

</style>
</head>
<body>

<%



String successMsg = request.getParameter("SuccessMsg");
String successMessage ="";
if("successCreate".equals(successMsg)){
	successMessage = "Event Created Successfully";
}else if("successUpdate".equals(successMsg)){
	successMessage = "Event Updated Successfully";	
}else if("deactivated".equals(successMsg)){
	successMessage = "Event Deactivated Successfully";	
}else if("deleted".equals(successMsg)){
	successMessage = "Event Deleted Successfully";
}


String errCode = request.getParameter("errCode");
String errorCode ="";
if("invalidEventId".equals(successMsg)){
	successMessage = "No such event ID exist";
}else if("eventNotFound".equals(successMsg)){
	successMessage = "No such event exist";	
}else if("InvalidRequest".equals(successMsg)){
	successMessage = "You're Accessing not validated";	
}else if("alreadyInactive".equals(successMsg)){
	successMessage = "Event is already inactive";	
}else if("hasSignups".equals(successMsg)){
	successMessage = "There is participant who has signed up for this event!";	
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
		<form action="listEvents.jsp" method="get" class="searchBar">
			<input type="text" class="grid" name="search" placeholder="Search event name..." value="<%= escapeHtml(search) %>">
			<select name="status" class="grid">
				<option value="">All Statuses</option>
				<option value="Upcoming" <%= "Upcoming".equals(statusFilter) ? "selected" : "" %>>Upcoming</option>
				<option value="Ongoing" <%= "Ongoing".equals(statusFilter) ? "selected" : "" %>>Ongoing</option>
				<option value="Completed" <%= "Completed".equals(statusFilter) ? "selected" : "" %>>Completed </option>
				<option value="Cancelled" <%= "Cancelled".equals(statusFilter) ? "selected" : "" %>>Cancelled</option>
			</select>
		<button type="submit" class="btn btnPrimary">Search</button>
		</form>
	<div class="card">
	
	<% if (!successMessage.isEmpty()) { %>
    		<p class="msgBox msgSuccess"><%= successMessage %></p>
	<% } %>
	<% if (!errorCode.isEmpty()) { %>
    		<p class="msgBox msgError"><%= errorCode %></p>
	<% } %>
	
	
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
					
						<a href="viewEvent.jsp?eventId=<%=eventId%>"
							class="btn btnPrimary">View</a>
						<a href="editEvent.jsp?eventId=<%=eventId%>"
							class="btn btnPrimary">Edit</a>
						<form action="confirmEventDelete.jsp" method="post">
							<input type="hidden" name="eventId" value="<%=eventId%>">
							<button type="submit" class="btn btnPrimary">
								Delete
							</button>
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
					<a href="viewEventDetails.jsp?eventId=<%=eventId%>"
						class="btn btnPrimary">View</a>
					<a href="editEvent.jsp?eventId=<%=eventId%>"
						class="btn btnPrimary">Edit</a>
					<form action="confirmEventDeactivate.jsp" method="post">
						<input type="hidden" name="eventId" value="<%=eventId%>">
						<button type="submit" class="btn btnPrimary">Deactivate</button>
					</form>
					<form action="confirmEventDelete.jsp" method="post">
						<input type="hidden" name="eventId" value="<%=eventId%>">
						<button type="submit" class="btn btnPrimary">Delete</button>
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