<%--
Author: Htet Yamin Aung (P2535607)
Date: 22/11/2026
Description: ST0510/JAD Assignment 1 - Staff: confirm deactivation of a participant
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>

<%-- staff only: redirects anyone who is not a logged-in, active staff member --%>
<%@ include file="/auth/staffGuard.jsp" %>
<%
	//1. only reachable from the Deactivate button, which submits by POST
	if (!"POST".equals(request.getMethod())) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidRequest");
		return;
	}

	//2. the id arrives as text from the hidden field in listParticipants.jsp
	String idText = request.getParameter("id");

	if (idText == null) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidId");
		return;
	}

	int participantId;
	try {
		participantId = Integer.parseInt(idText.trim());
	} catch (NumberFormatException e) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidId");
		return;
	}

	//3. look up the participant's status and active sign-up count
	boolean found = false;
	String fullName = null;
	String username = null;
	boolean isActive = false;
	int signupCount = 0;
	Connection conn = null;

	try {
		// Step 1: Load JDBC Driver
		Class.forName("com.mysql.cj.jdbc.Driver");

		// Step 2: Read connection details from .env in WEB-INF
		Dotenv dotenv = Dotenv.configure().directory(application.getRealPath("/WEB-INF")).load();
		String connURL = dotenv.get("DB_URL");
		String dbUser = dotenv.get("DB_USERNAME");
		String dbPassword = dotenv.get("DB_PASSWORD");

		// Step 3: Establish connection
		conn = DriverManager.getConnection(connURL, dbUser, dbPassword);

		// Step 4: PreparedStatement; withdrawn sign-ups are not counted
		String sql = "SELECT p.full_name, u.username, u.is_active, COUNT(r.event_id) AS signup_count "
				+ "FROM participants p "
				+ "JOIN users u ON p.user_id = u.user_id "
				+ "LEFT JOIN registrations r ON r.participant_id = p.participant_id AND r.status <> 'Withdrawn' "
				+ "WHERE p.participant_id = ? "
				+ "GROUP BY p.participant_id, p.full_name, u.username, u.is_active";
		PreparedStatement ps = conn.prepareStatement(sql);
		ps.setInt(1, participantId);

		// Step 5: Execute query
		ResultSet rs = ps.executeQuery();

		// Step 6: Process result :we will use if instead of while
		//because it will return one row at most
		if (rs.next()) {
			found = true;
			fullName = rs.getString("full_name");
			username = rs.getString("username");
			isActive = rs.getBoolean("is_active");
			signupCount = rs.getInt("signup_count");
		}
	} catch (ClassNotFoundException e) {
		System.err.println("confirmParticipantDeactivate.jsp - driver not found: " + e);
		response.sendRedirect("listParticipants.jsp?errCode=dbError");
		return;
	} catch (SQLException e) {
		System.err.println("confirmParticipantDeactivate.jsp - SQL error: " + e);
		response.sendRedirect("listParticipants.jsp?errCode=dbError");
		return;
	} catch (DotenvException e) {
		System.err.println("confirmParticipantDeactivate.jsp - .env error: " + e);
		response.sendRedirect("listParticipants.jsp?errCode=dbError");
		return;
	} catch (Exception e) {
		System.err.println("confirmParticipantDeactivate.jsp - " + e);
		response.sendRedirect("listParticipants.jsp?errCode=dbError");
		return;
	} finally {
		// Step 7: Close connection
		if (conn != null) {
			try {
				conn.close();
			} catch (SQLException e) {
				System.err.println("Error closing connection: " + e);
			}
		}
	}

	//Each failed check returns to the list with its own message
	if (!found) {
		response.sendRedirect("listParticipants.jsp?errCode=notFound");
		return;
	}
	if (!isActive) {
		response.sendRedirect("listParticipants.jsp?errCode=alreadyInactive");
		return;
	}
	if (signupCount > 0) {
		response.sendRedirect("listParticipants.jsp?errCode=hasSignups");
		return;
	}
%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Deactivate participant - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
	<main class="page">
	<%-- shared header--%>
	<%@ include file="/shared/header.jsp" %>
	
		<div class="card">
			<h1 class="pageTitle">Deactivate participant?</h1>
			<p class="pageSub">
				You are about to deactivate
				<strong><%= escapeHtml(fullName) %></strong>
				(P<%= twoDigits(participantId) %> · <%= escapeHtml(username) %>).
			</p>
			<div class="msgBox msgWarn">
				The participant will no longer be able to log in. Their details will be kept.
			</div>

			<div class="formActions confirmActions">
				<a class="btn" href="listParticipants.jsp">Cancel</a>
				<%-- the id is passed on to the page that performs the update --%>
				<form action="deactivateParticipant.jsp" method="post">
					<input type="hidden" name="id" value="<%= participantId %>">
					<button type="submit" class="btn btnDark">Deactivate</button>
				</form>
			</div>
		</div>
		<%@ include file="/shared/footer.html" %>
	</main>
</body>
</html>
