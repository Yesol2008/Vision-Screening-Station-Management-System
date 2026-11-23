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
<title>Events</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
<style>

	.searchBar{
	display: grid;
    grid-template-columns: 6fr 2fr 1fr;;
    gap: 20px;
    padding: 20px;
	}
	.btnGrid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 8px;
	width: 220px;
	}

	.btnGrid form {
	margin: 0;
	}

	.btnGrid .btn {
	display: block;
	width: 100%;
	padding: 8px 10px;
	font-size: 14px;
	text-align: center;
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
if("invalidEventId".equals(errCode)){
	errorCode = "Invalid event ID.";
}else if("eventNotFound".equals(errCode)){
	errorCode = "No such event exist";	
}else if("InvalidRequest".equals(errCode)){
	errorCode = "Invalid request. Please try again.";
}else if("alreadyInactive".equals(errCode)){
	errorCode = "Event is already inactive";	
}else if("hasSignups".equals(errCode)){
	errorCode = "There is participant who has signed up for this event!";	
}else if("dbError".equals(errCode)){
	errorCode="Something went wrong. Please try again later.";
	
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
    	String search = request.getParameter("search");
	String statusFilter = request.getParameter("status");
	

		if (search != null && search.trim().isEmpty()) {
		    search = null;
		}
	
		if (statusFilter != null && statusFilter.trim().isEmpty()) {
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
	<%@ include file="/WEB-INF/shared/header.jsp" %>
	
	
	<div class="titleRow">
			<h1>Events</h1>
		<form action="createEvent.jsp" method="get">
			<input type="submit" value="Create New Event" class="btn btnDark">
		</form>
	</div>
	<p class="intro">Manage event record and view the sign-ups.</p>
		<label class="searchLabel">Search events</label>
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
	

		<table class="dataTable">
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
				<td><%=escapeHtml(event_name) %></td>
				<td><%=escapeHtml(event_date)%></td>
				<td><%=escapeHtml(location)%></td>
				<td><span class="badge badgeInactive"><%=escapeHtml(status)%></span></td>
				<td>
					<form action="viewEventParticipants.jsp" method="post">
						<input type="submit" class="btn btnPrimary" value="<%=participants%> signed up">
						<input type="hidden" name="eventId" value="<%=eventId%>">
					</form>
				</td>
				<td>
					<div class="btnGrid">
					<a href="viewEvent.jsp?eventId=<%=eventId%>"
						class="btn">View</a>
					<a href="editEvent.jsp?eventId=<%=eventId%>"
						class="btn">Edit</a>
					<form action="confirmEventDelete.jsp" method="post">
						<input type="hidden" name="eventId" value="<%=eventId%>">
							<button type="submit" class="btn">
								Delete
							</button>
					</form>				
					</div>
				</td>
			</tr>
                    	<%
                    }else{
                    
                    %>
                    
            <tr>
				<td><%=escapeHtml(event_name) %></td>
				<td><%=escapeHtml(event_date)%></td>
				<td><%=escapeHtml(location)%></td>
				<td><span class="badge"><%=escapeHtml(status)%></span></td>
				<td>
					<form action="viewEventParticipants.jsp" method="post">
						<input type="submit" class="btn btnPrimary" value="<%=participants%> signed up">
						<input type="hidden" name="eventId" value="<%=eventId%>">
					</form>
				</td>
				<td>
					<div class="btnGrid">
					<a href="viewEventDetails.jsp?eventId=<%=eventId%>"
						class="btn">View</a>
					<a href="editEvent.jsp?eventId=<%=eventId%>"
						class="btn">Edit</a>
					<form action="confirmEventDeactivate.jsp" method="post">
						<input type="hidden" name="eventId" value="<%=eventId%>">
						<button type="submit" class="btn">Deactivate</button>
					</form>
					<form action="confirmEventDelete.jsp" method="post">
						<input type="hidden" name="eventId" value="<%=eventId%>">
						<button type="submit" class="btn">Delete</button>
					</form>		
					</div>
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
	}catch (ClassNotFoundException e) {
		System.err.println("JDBC Driver not found"+ e);
		errorCode = "Unable to connect to the server. Please try again later.";

	} catch (SQLException e) {
		System.err.println("Database error in login.jsp"+ e);
		errorCode = "Unable to connect to the server. Please try again later.";

	}catch (DotenvException e) {
		System.err.println("Environment configuration error in browseEvents.jsp"+ e);
		errorCode="Something went wrong. Please try again later.";

	}catch (Exception e) {
        System.err.println("Database connection error"+ e);
		errorCode="Something went wrong. Please try again later.";
    }


%>
</body>
</html>