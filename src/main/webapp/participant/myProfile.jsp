<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="io.github.cdimascio.dotenv.DotenvException" %>
<%--
	Author: Htet Yamin Aung (P2535607)
	Description: ST0510/JAD Assignment 1 - Participant > My profile (view)

	Shows the signed-in participant's own details.
	The record is found with the userId from the session (via the guard),
	so participants can only see their own profile.
	"Edit my profile" -> profileEdit.jsp, which redirects back here with ?msg=updated or a specific errCode
--%>

<%@ include file="/auth/participantGuard.jsp" %>
<%
	// messages sent here by other pages
	String msg = request.getParameter("msg");
	String errCode = request.getParameter("errCode");
	String successMessage = null;
	String errMessage = null;

	if (msg != null && msg.equals("updated")) {
		successMessage = "Your profile has been updated.";
	}
	if (errCode != null && errCode.equals("notAuthorised")) {
		// a participant tried to open a staff page
		errMessage = "You don't have access to that page.";
	}

	// values shown in the details card (filled from the database below)
	int participantId = 0;
	String username = null;
	String fullName = null;
	String contactNum = null;
	String email = null;
	boolean found = false;
	String loadErr = null;

	Connection conn = null;

	try {
		// Step 1: Load the JDBC driver
		Class.forName("com.mysql.cj.jdbc.Driver");

		// Step 2: Read the database connection details from WEB-INF/.env
		Dotenv dotenv = Dotenv.configure()
				.directory(application.getRealPath("/WEB-INF")).load();

		// Step 3: Connect to the database
		conn = DriverManager.getConnection(dotenv.get("DB_URL"),
				dotenv.get("DB_USERNAME"), dotenv.get("DB_PASSWORD"));

		// Step 4: PreparedStatement - find the profile by the userId from the session
		PreparedStatement ps = conn.prepareStatement(
				"SELECT p.participant_id, u.username, p.full_name, p.contact_number, p.email "
				+ "FROM participants p JOIN users u ON p.user_id = u.user_id "
				+ "WHERE p.user_id = ?");
		ps.setInt(1, currentUserId);

		// Step 5: Execute
		ResultSet rs = ps.executeQuery();

		// Step 6: Process result - one row at most (user_id is UNIQUE in participants), so use if
		if (rs.next()) {
			found = true;
			participantId = rs.getInt("participant_id");
			username = rs.getString("username");
			fullName = rs.getString("full_name");
			contactNum = rs.getString("contact_number");
			email = rs.getString("email");
		}
		// Catch errors: print details to the console for debugging,
		// but show the user a general message
	} catch (ClassNotFoundException e) {
		System.err.println("myProfile.jsp - JDBC driver not found :" + e);
		loadErr = "Sorry, your profile could not be loaded. Please try again later.";
	} catch (SQLException e) {
		System.err.println("myProfile.jsp - database error :" + e);
		loadErr = "Sorry, your profile could not be loaded. Please try again later.";
	} catch (DotenvException e) {
		System.err.println("myProfile.jsp - .env file error :" + e);
		loadErr = "Sorry, your profile could not be loaded. Please try again later.";
	} catch (Exception e) {
		System.err.println("myProfile.jsp - unexpected error :" + e);
		loadErr = "Sorry, your profile could not be loaded. Please try again later.";
	} finally {
		// Step 7: Close the connection
		if (conn != null) {
			try {
				conn.close();
			} catch (SQLException e) {
				System.err.println("Error closing connection :" + e);
			}
		}
	}
%>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>My profile - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>

<div class="page">
<%@ include file="/shared/header.jsp" %>
	<div class="titleRow">
		<h1>My profile</h1>
		<a class="btn btnDark" href="profileEdit.jsp">Edit my profile</a>
	</div>
	<p class="intro">Keep your own contact details up to date.</p>

	<%-- messages from other pages --%>
	<% if (successMessage != null) { %>
		<div class="msgBox msgSuccess"><%= successMessage %></div>
	<% } %>
	<% if (errMessage != null) { %>
		<div class="msgBox msgError"><%= errMessage %></div>
	<% } %>

	<%-- the details card, or a message if they couldn't be loaded --%>
	<% if (loadErr != null) { %>
		<div class="msgBox msgError"><%= loadErr %></div>
	<% } else if (!found) { %>
		<div class="msgBox msgError">Your profile could not be found.</div>
	<% } else { %>
		<div class="detailCard">
			<div class="detailRow"><span class="detailLabel">Participant ID</span><span>P<%= twoDigits(participantId) %></span></div>
			<div class="detailRow"><span class="detailLabel">Username</span><span><%= escapeHtml(username) %></span></div>
			<div class="detailRow"><span class="detailLabel">Role</span><span>Participant</span></div>
			<div class="detailRow"><span class="detailLabel">Full name</span><span><%= escapeHtml(fullName) %></span></div>
			<div class="detailRow"><span class="detailLabel">Contact number</span><span><%= escapeHtml(contactNum) %></span></div>
			<div class="detailRow"><span class="detailLabel">Email</span><span><%= escapeHtml(email) %></span></div>
		</div>
	<% } %>
	
	<%@ include file="/shared/footer.html" %>
</div>
</body>
</html>