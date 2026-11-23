<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
    
<%
Integer userId = (Integer) session.getAttribute("userId");
String role = null; 
String message = "";
if (userId != null) {
	try {
		Dotenv dotenv = Dotenv.configure()
				.directory(application.getRealPath("/WEB-INF"))
				.load();

		String connURL = dotenv.get("DB_URL");
		String dbUser = dotenv.get("DB_USERNAME");
		String dbPass = dotenv.get("DB_PASSWORD");

		Class.forName("com.mysql.cj.jdbc.Driver");

		if(userId != null){
		String sql = "SELECT role FROM users WHERE user_id = ?";

		try (Connection conn = DriverManager.getConnection(connURL, dbUser, dbPass);
			 PreparedStatement ps = conn.prepareStatement(sql)) {

			ps.setInt(1, userId);

			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					role = rs.getString("role");
				}
			}
		}
		
		}
	}catch (ClassNotFoundException e) {
		System.err.println("JDBC Driver not found"+ e);
	    message = "Unable to connect to the server. Please try again later.";

	} catch (SQLException e) {
		System.err.println("Database error in login.jsp"+ e);
	    message = "Unable to connect to the server. Please try again later.";

	}catch (DotenvException e) {
		System.err.println("Environment configuration error in browseEvents.jsp"+ e);
		message="Something went wrong. Please try again later.";

	} catch (Exception e) {
		application.log("Index role lookup failed", e);
	}
}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Vision Screening Management System-Overview</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
<style>
.grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
	gap: 20px;
}

.quickCard{
	display: flex;
	flex-direction: column;
	padding: 24px;
	background: var(--white);
	border: 1px solid var(--borderLight);
	border-top: 4px solid var(--teal);
	border-radius: 12px;
	box-shadow: 0 4px 16px rgba(21, 50, 79, 0.06);
}

.quickCard h2 {
	margin: 0 0 8px;
	font-size: 20px;
}

.quickCard p {
	margin: 0 0 20px;
	color: var(--grey);
}

.quickCard .btn {
	margin-top: auto;
	align-self: flex-start;
	text-align: center;
}
</style>
</head>
<body>

<div class="page">

<%@ include file="/WEB-INF/shared/header.jsp" %>

	<div class="card">
		<h1> Vision Screening Management System</h1>
<% if ("STAFF".equalsIgnoreCase(role)) { %>


<h1 class="pageTitle">Admin dashboard</h1>
	<p class="pageSub">Manage events and participants.</p>

	<div class="grid">
		<div class="quickCard">
			<h2>Events</h2>
			<p>Create, edit and deactivate events.</p>
			<a href="staff/listEvents.jsp">View Events</a>
		</div>
		<div class="quickCard">
			<h2>Participants</h2>
			<p>View and manage registered participants.</p>
			<a href="staff/listParticipants.jsp">View Participants</a>
		</div>
	</div>


<%} else if("PARTICIPANT".equalsIgnoreCase(role)){%>		

	<h1 class="pageTitle">Welcome back</h1>
	<p class="pageSub">Find events and manage your signups.</p>

	<div class="grid">
		<div class="quickCard">
			<h2>Browse events</h2>
			<p>See what's coming up and sign up.</p>
			<a href="participant/browseEvents.jsp">Browse events</a>
		</div>
		<div class="quickCard">
			<h2>My sign-up's</h2>
			<p>View or cancel your registrations.</p>
			<a href="participant/mySignups.jsp">My sign-up's</a>
		</div>
		<div class="quickCard">
			<h2>My profile</h2>
			<p>Check your account details.</p>
			<a href="participant/myProfile.jsp">My profile</a>
		</div>
	</div>



<%}else{%>
		<div class="title titleRow">
			<h2 class="pageTitle">Get started with your Vision-Screening</h2>
			<a href="login.jsp" class="btn btnDark">Login</a>
		</div>
			<p class="pageSub">Get started with browsing events and managing your sign-up's.</p>
		
		<div class="grid">
			<div class="quickCard">
				<h2>Participant</h2>
				<p>Update your own profile, sign up for multiple events and manage your commitments.</p>
			</div>
			<div class="quickCard">
				<h2>Staffs</h2>
				<p>Create and manage events, administer screening participants and view participant sign-ups.</p>
			</div>
			<div class="quickCard">
				<h2>Create participant account</h2>
				<p>Participants can register themselves or use pre-populated accounts. Staff accounts are pre-populated.</p>
				<a href="register.jsp">Create an account</a>
			</div>
		</div>
<%} %>
		
	</div>


	<jsp:include page="/footer.jsp"/>


</div>

</body>
</html>